class Admin::ProductsController < ApplicationController
  before_action :require_administrator

  def index
    @products = Product.order('price asc')
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path, notice: 'Added product successfully!'
    else
      puts @product.errors.inspect
      flash.now[:error] = 'Please enter all required fields below'
      render :new
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update_attributes(product_params)
      redirect_to admin_products_path, notice: 'Updated product successfully!'
    else
      puts @product.errors.inspect
      flash.now[:error] = 'Please enter all required fields below'
      render :edit
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :quantity, :price, :active, :paypal_button_code, :offer_code)
  end
end
