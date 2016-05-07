class Admin::LocationsController < ApplicationController
  before_action :require_administrator

  def index
    @locations = Location.order('name asc')
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)
    if @location.save
      redirect_to admin_locations_path, notice: 'Added location successfully!'
    else
      puts @location.errors.inspect
      flash.now[:error] = 'Please enter all required fields below'
      render :new
    end
  end

  def edit
    @location = Location.find(params[:id])
  end

  def update
    @location = Location.find(params[:id])
    if @location.update_attributes(location_params)
      redirect_to admin_locations_path, notice: 'Updated location successfully!'
    else
      puts @location.errors.inspect
      flash.now[:error] = 'Please enter all required fields below'
      render :edit
    end
  end

  private

  def location_params
    params.require(:location).permit(:name, :street_address, :city, :state, :zip_code)
  end
end
