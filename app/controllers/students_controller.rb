class StudentsController < ApplicationController
  def index
    @students = current_user.students.order('first_name')
  end

  def new
    @student = current_user.students.build
  end

  def create
    @student = current_user.students.build(student_params)
    if @student.save
      redirect_to students_path, notice: 'Added student successfully!'
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :new
    end
  end

  def edit
    @student = current_user.students.find(params[:id])
  end

  def update
    @student = current_user.students.find(params[:id])
    if @student.update_attributes(student_params)
      redirect_to students_path, notice: 'Updated student successfully!'
    else
      flash.now[:error] = 'Please enter all required fields below'
      render :edit
    end
  end

  private

  def student_params
    parms = params.require(:student).permit(:first_name, :last_name, :dob, :avatar)
    parms[:dob] = Chronic.parse(parms[:dob])
    parms
  end
end
