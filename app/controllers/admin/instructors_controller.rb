class Admin::InstructorsController < ApplicationController
  before_action :require_administrator

  def index
    @instructors = ::User.instructor.order(last_name: :asc)
  end

  def new
    @instructor = ::User.new(role: 'instructor', is_instructor: true)
  end

  def edit
    @instructor = ::User.instructor.find(params[:id])
  end
end
