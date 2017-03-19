class Admin::UsersController < ApplicationController
  before_action :require_administrator, except: [:lesson_transfer_details, :transfer_lessons, :perform_transfer]
  helper_method :sort_column, :sort_direction

  def index
    @users = User.where("1 = 1")
    if params[:q]
      @users = @users.where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?", "%#{params[:q].downcase}%", "%#{params[:q].downcase}%", "%#{params[:q].downcase}%")
    end
    @users = @users.customer if params[:role] == "customers"
    @users = @users.instructor if params[:role] == "instructors"

    @users = @users.order("last_name asc").page(params[:page])
  end

  def show
    @user = User.find(params[:id])
    render template: '/profile/show'
  end

  def new
    @user = User.new(role: nil)
  end

  def create
    @user = User.new(user_params)
    @user.i_agree = true if @user.role != 'customer'
    if @user.save
      if @user.is_instructor
        redirect_to admin_instructors_path, notice: 'Added instructor successfully!'
      else  
        redirect_to admin_users_path, notice: 'Added user successfully!'
      end
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.i_agree = true if @user.role != 'customer'
    if @user.update_attributes(user_params)
      if @user.is_instructor
        redirect_to admin_instructors_path, notice: 'Updated instructor successfully!'
      else  
        redirect_to admin_users_path, notice: 'Updated user successfully!'
      end
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :edit
    end
  end

  def login_as
    new_user = User.find(params[:id])
    session[:original_user_id] = current_user.id
    warden.set_user(new_user, :scope => :user)
    redirect_to '/'
  end

  def search
    q = params[:q]
    results = User.where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?', "%#{q.downcase}%", "%#{q.downcase}%", "%#{q.downcase}%").limit(15)
    render json: results
  end

  def order_details
    @user = User.find(params[:id])
    @order = @user.orders.find(params[:order_id])
    @lessons = @order.lessons.order('created_at asc')
    render layout: false
  end

  def lesson_transfer_details
    @user = User.find(params[:id])
    @lesson_transfer = LessonTransfer.find(params[:lesson_transfer_id])
    render layout: false
  end

  def add_lessons
    @user = User.find(params[:id])
    render layout: false
  end

  def create_lessons
    @user = User.find(params[:id])
    order_id = params[:paypal].present? ? params[:paypal] : SecureRandom.uuid
    order = Order.new({
      user_id: @user.id,
      quantity: params[:quantity],
      total: params[:total],
      remote_order_id: order_id,
      merchant_response: {
        paypal_transaction: order_id,
        orderid: order_id,
        notes: params[:notes]
      }
    })

    if order.save
      order.quantity.times do
        if Lesson.where(order_id: order.id).count < order.quantity
          Lesson.create!(order_id: order.id, user_id: @user.id, purchased_at: order.created_at, expires_at: order.created_at + 1.year)
        end
      end
      redirect_to admin_user_path(@user), notice: 'Added lessons successfully!'
    else
      redirect_to admin_user_path(@user), alert: 'Unable to save lessons'
    end
  end

  def transfer_lessons
    @user = User.find(params[:id])
    render layout: false
  end

  def perform_transfer
    quantity = params[:quantity].to_i
    recipient = User.find_by(email: params[:recipient_email])
    notes = params[:notes]

    if recipient.blank?
      render({
        json: {
          message: "There are no members with the email provided in our system. Please make sure they sign up for Aquatics Academy prior to transferring lessons to them."
        },
        status: :unprocessible_entity
      })
      return
    end

    lessons = current_user.lessons.unassigned.order(expires_at: :desc).limit(quantity)
    if lessons.count == quantity
      lesson_transfer = LessonTransfer.create!(
        quantity: quantity,
        user_id: current_user.id,
        recipient_id: recipient.id,
        notes: notes
      )

      lessons.each do |lesson|
        lesson.update_attributes({
          user_id: recipient.id,
          lesson_transfer_id: lesson_transfer.id
        })
      end

      Notification.lesson_transferred(lesson_transfer).deliver_now

      flash[:notice] = "You successfully transferred #{params[:quantity]} lessons to #{recipient.full_name}"
      render json: { ok: true }
    else
      render({
        json: {
          message: "You have selected to transfer more lessons than are available for transfer."
        },
        status: :unprocessible_entity
      })
    end
  end

  def delete_order
    user = User.find(params[:id])
    order = Order.find(params[:order_id])
    order.destroy
    redirect_to admin_user_path(user), notice: 'Removed order successfully!'
  end

  def delete_lessons
    user = User.find(params[:id])
    lesson_ids = [params[:lesson_id]].flatten
    lessons = user.lessons.where(id: lesson_ids)
    lessons.each do |lesson|
      TimeSlot.where(lesson_id: lesson.id).map(&:unassign_student!)
    end

    lessons.destroy_all
    redirect_to admin_user_path(user), notice: 'Removed lessons successfully!'
  end

  private

  def user_params
    parms = params.require(:user).permit(:first_name, :last_name, :email, :phone, :role, :profile, :avatar,
      :password, :password_confirmation, :is_instructor, :is_private_instructor, :instructor_invite_code)
    parms[:private_instructor_ids] = params[:user][:private_instructor_ids].try(:keys) || []
    parms
  end

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "last_name"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
