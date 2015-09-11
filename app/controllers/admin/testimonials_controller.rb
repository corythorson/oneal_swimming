class Admin::TestimonialsController < ApplicationController
  before_action :require_administrator

  def index
    @testimonials = Testimonial.order('id asc')
  end

  def new
    @testimonial = Testimonial.new
  end

  def create
    @testimonial = Testimonial.new(testimonial_params)
    if @testimonial.save
      redirect_to admin_testimonials_path, notice: 'Added testimonial successfully!'
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :new
    end
  end

  def edit
    @testimonial = Testimonial.find(params[:id])
  end

  def update
    @testimonial = Testimonial.find(params[:id])
    if @testimonial.update_attributes(testimonial_params)
      redirect_to admin_testimonials_path, notice: 'Updated testimonial successfully!'
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :edit
    end
  end

  private

  def testimonial_params
    params.require(:testimonial).permit(:name, :body)
  end
end
