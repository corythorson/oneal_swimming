class HomeController < ApplicationController
  def index
    return redirect_to params[:redir] if params[:redir].present?
    redirect_to scheduler_path(location_id: "sandy-pool")
  end

  def our_lessons
    if params.has_key?(:success)
      flash.now[:notice] = 'Your purchase was successful!'
    end
    @products = []
    Product.active.order('price asc').each do |product|
      if product.offer_code == params[:offer_code].try(:strip) || product.offer_code.blank?
        @products << product
      end
    end
  end

  def set_cookie
    render layout: false
  end

  def testimonials
    @testimonials = Testimonial.all
  end

  def instructors
    @instructors = User.instructor.order('last_name asc')
  end

  def contact
  end

  def submit_contact
    Notification.contact(params[:name], params[:email], params[:message]).deliver_now
    redirect_to contact_path, notice: 'Your message has been received!'
  end

  def terms_agreement
  end

  def terms_i_agree
    current_user.update_attribute(:i_agree, true)
    redirect_to profile_path, notice: "Thank you. You may now schedule your lessons."
  end

  def terms
  end

  # params == {
  #   "stripeToken"=>"tok_177JxWAxb7nsh6KmuOM2Qsrk",
  #   "stripeTokenType"=>"card",
  #   "stripeEmail"=>"cavneb@gmail.com",
  #   "p"=>0 # index of product in Product.options
  # }
  def process_purchase
    product = Product.find(params[:order][:productId])
    tokenData = {
      stripeToken: params[:token][:id],
      stripeTokenType: params[:token][:type],
      stripeEmail: params[:token][:email],
      p: 0,
      amount: params[:order][:amount],
      quantity: params[:order][:quantity]
    }
    order, error = ChargeCustomer.call(current_user, product, tokenData)
    if order
      render json: { success: true }
      # redirect_to our_lessons_path, notice: 'Your purchase was successful!'
    else
      # flash[:error] = error.message
      render json: { success: false, error: error.message }, status: 404
      # redirect_to our_lessons_path
    end
  end

  def return_to_admin
    if session[:original_user_id].present?
      new_user = User.find(session[:original_user_id])
      warden.set_user(new_user, :scope => :user)
      redirect_to root_url
    else
      render status: 404
    end
  end
end
