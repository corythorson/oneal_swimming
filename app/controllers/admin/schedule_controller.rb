class Admin::ScheduleController < ApplicationController
  before_action :require_administrator

  def index
    @date = params[:date].present? ? Date.strptime(params[:date], '%m/%d/%Y') : Date.current
    @t1 = @date.beginning_of_day + 8.hours
    @t2 = @date.beginning_of_day + 19.hours
  end

  def update
    @date = Chronic.parse(params[:date]).in_time_zone
    User.instructor.each do |instructor|
      TimeSlot.by_instructor(instructor.id).by_date_range(@date, @date).where(student_id: nil).destroy_all
      if params[:instructors].present?
        data = params[:instructors][instructor.id.to_s]
        if data
          data[:times].each do |time|
            d = Chronic.parse(time)
            TimeSlot.create!({
                start_at: d,
                duration: 20,
                instructor_id: instructor.id
              })
          end
        end
      end
    end
    redirect_to admin_schedule_path(params: { date: @date.strftime('%m/%d/%Y') })
  end

  def destroy_time_slot
    time_slot = TimeSlot.find(params[:id])
    d = time_slot.start_at.strftime('%F')
    if time_slot.deleteable?
      time_slot.destroy
      redirect_to root_path(params: { date: d }), notice: 'Time slot was deleted'
    else
      redirect_to root_path(params: { date: d }), alert: 'Cannot delete time slot'
    end
  end

end
