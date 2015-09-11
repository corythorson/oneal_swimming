class Admin::UsersController < ApplicationController
  before_action :require_administrator
  helper_method :sort_column, :sort_direction

  def index
    @users = User.where("1 = 1")
    if params[:q]
      @users = @users.where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end
    @users = @users.order("last_name asc").page(params[:page])
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new(role: nil)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: 'Added user successfully!'
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
    if @user.update_attributes(user_params)
      redirect_to admin_users_path, notice: 'Updated user successfully!'
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

  def add_lessons
    @user = User.find(params[:id])
    render layout: false
  end

  def create_lessons
    @user = User.find(params[:id])
    order = Order.new({
      user_id: @user.id,
      quantity: params[:quantity],
      total: params[:total],
      merchant_response: {
        paypal_transaction: params[:paypal],
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

  def delete_order
    user = User.find(params[:id])
    order = Order.find(params[:order_id])
    order.destroy
    redirect_to admin_user_path(user), notice: 'Removed order successfully!'
  end

  def delete_lessons
    user = User.find(params[:id])
    lesson_ids = params[:lesson_id]
    user.lessons.where(id: lesson_ids).destroy_all
    redirect_to admin_user_path(user), notice: 'Removed lessons successfully!'
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :role, :profile, :avatar,
      :password, :password_confirmation, :is_instructor)
  end

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "last_name"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
