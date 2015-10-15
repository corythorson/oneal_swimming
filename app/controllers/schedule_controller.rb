class ScheduleController < ApplicationController
  skip_before_action :verify_authenticity_token, except: [:index, :scheduler]

  def index
    @show_scheduler = true
  end

  def scheduler
    if params[:date].present?
      @date = Time.parse(params[:date]).to_datetime || Date.current
    else
      @date = Date.current
    end
    @start_time = @date.beginning_of_day + 8.hours
    @end_time = @date.beginning_of_day + 19.hours - 20.minutes
    puts "------------------------------------------------------------------"
    puts "#{@start_time} - #{@end_time}"
    puts "------------------------------------------------------------------"
    @instructors = User.instructors_for_date(@date).includes(:time_slots)
  end

  def assign_time_slot
    @time_slot = TimeSlot.find(params[:id])
    if current_user
      @students = current_user.students.order('first_name asc')
      @remaining_lessons = current_user.lessons.unassigned
      @lesson = @remaining_lessons.order('expires_at asc').first
    end
    render layout: false
  end

  def assign_student_to_time_slot
    time_slot = TimeSlot.find(params[:time_slot_id])
    student = current_user.students.find(params[:student_id])
    lesson = current_user.lessons.unassigned.order('expires_at asc').first

    if lesson
      if time_slot.available?
        time_slot.assign_student(student, lesson)
        redirect_to scheduler_path(date: time_slot.start_at.to_date), notice: "We have added #{student.first_name} to that time slot!"
      else
        redirect_to scheduler_path(date: time_slot.start_at.to_date), alert: "Time slot is no longer available"
      end
    else
      redirect_to scheduler_path(date: time_slot.start_at.to_date), alert: "You have no more lessons available"
    end
  end

  def unassign_time_slot
    @time_slot = TimeSlot.find(params[:id])
    @remaining_lessons = current_user.lessons.unassigned
    render layout: false
  end

  def perform_unassign_time_slot
    time_slot = TimeSlot.find(params[:id])

    if time_slot && time_slot.can_unassign?(current_user)
      time_slot.unassign_student!
      redirect_to scheduler_path(date: time_slot.start_at.to_date), notice: "You have been unassigned from that time slot"
    else
      redirect_to scheduler_path(date: time_slot.start_at.to_date), alert: "You are not allowed to unschedule this time slot"
    end
  end

  def switch_time_slot_times
    student = Student.find(params[:student_id])
    unless current_user.admin?
      student = current_user.students.find(params[:student_id])
    end
    old_time_slot = TimeSlot.find(params[:old_time_slot_id])
    new_time_slot = TimeSlot.find(params[:new_time_slot_id])

    if student && new_time_slot.available?
      lesson = old_time_slot.lesson
      old_time_slot.unassign_student!
      new_time_slot.assign_student(student, lesson)
      redirect_to scheduler_path(date: new_time_slot.start_at.to_date), notice: "Time slot changed successfully!"
    else
      redirect_to scheduler_path(date: new_time_slot.start_at.to_date), alert: "Time slot is no longer available"
    end
  end

  # def events
  #   date_from = Chronic.parse(params[:date_from]) || Date.current
  #   date_to = Chronic.parse(params[:date_to]) || Date.current
  #
  #   ret = { from: date_from.strftime('%F'), to: date_to.strftime('%F'), instructors: [] }
  #
  #   User.instructor.order('first_name').each do |instructor|
  #     instructor_data = { id: instructor.id, first_name: instructor.first_name, avatar: instructor.avatar.thumb.url }
  #
  #     time_slots = {}
  #     TimeSlot.by_date_range(date_from, date_to).where(instructor_id: instructor.id).each do |ts|
  #       time_slots[ts.start_at.strftime('%F-%H-%M')] = ts.to_react_event
  #     end
  #
  #     instructor_data[:time_slots] = time_slots
  #     ret[:instructors] << instructor_data
  #   end
  #
  #   render json: ret
  # end
  #
  # def time_slots
  #   date_from = Date.parse(params[:start])
  #   date_to = Date.parse(params[:end])
  #   render json: TimeSlot.by_date_range(date_from, date_to)
  # end
  #
  # def instructors
  #   render json: User.instructor.order('first_name').map(&:to_scheduler)
  # end
  #
  # def assign
  #   time_slot = TimeSlot.find(params[:time_slot_id])
  #   student = current_user.students.find(params[:student_id])
  #   lesson = current_user.lessons.unassigned.order('expires_at asc').first
  #
  #   if lesson
  #     if time_slot.available?
  #       time_slot.assign_student(student, lesson)
  #       render json: { error: nil }
  #     else
  #       render json: { error: 'Time slot is no longer available' }
  #     end
  #   else
  #     render json: { error: 'No lessons available' }
  #   end
  # end
  #
  # def unassign
  #   time_slot = TimeSlot.find(params[:time_slot_id])
  #
  #   if time_slot && time_slot.can_unassign?(current_user)
  #     time_slot.unassign_student!
  #     render json: { error: nil }
  #   else
  #     render json: { error: 'Not permitted' }
  #   end
  # end
end
