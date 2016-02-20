class HomeController < ApplicationController
  def index
  end

  def our_lessons
    @products = []
    Product.active.order('price asc').each do |product|
      if product.offer_code == params[:offer_code].try(:strip) || product.offer_code.blank?
        @products << product
      end
    end
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

  # params == {
  #   "stripeToken"=>"tok_177JxWAxb7nsh6KmuOM2Qsrk",
  #   "stripeTokenType"=>"card",
  #   "stripeEmail"=>"cavneb@gmail.com",
  #   "p"=>0 # index of product in Product.options
  # }
  def process_purchase
    product = Product.find(params[:id])
    order, error = ChargeCustomer.call(current_user, product, params)
    if order
      redirect_to our_lessons_path, notice: 'Your purchase was successful!'
    else
      flash[:error] = error.message
      redirect_to our_lessons_path
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
