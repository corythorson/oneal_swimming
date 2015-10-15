class Admin::ScheduleController < ApplicationController
  before_action :require_administrator

  def index
    @date = params[:date].present? ? Date.strptime(params[:date], '%m/%d/%Y') : Date.current
    @date_from = params[:start].present? ? Date.strptime(params[:start], '%F').beginning_of_day : Date.current.beginning_of_day
    @date_to = params[:end].present? ? Date.strptime(params[:end], '%F').end_of_day : Date.current.end_of_day
    @t1 = @date.beginning_of_day + 8.hours
    @t2 = @date.beginning_of_day + 19.hours
    @time_slots = TimeSlot.by_date_range(@date_from, @date_to)

    events = []
    @time_slots.includes(:user).each do |time_slot|
      events << {
        id: time_slot.id,
        resourceId: time_slot.instructor_id,
        title: ' ',
        start: time_slot.start_at.strftime('%FT%T'),
        end: (time_slot.start_at + time_slot.duration.minutes).strftime('%FT%T'),
        unassign_path: admin_unassign_time_slot_path(time_slot.id),
        destroy_path: admin_delete_time_slot_path(time_slot.id),
        color: time_slot.deleteable? ? '#37c605' : '#cb0000',
        can_destroy: time_slot.deleteable?
      }
    end

    respond_to do |format|
      format.html { render :fullcalendar }
      format.json { render :json => events.as_json }
   end
  end

  def schedule_builder
    @date = Date.current
    @t1 = @date.beginning_of_day + 8.hours
    @t2 = @date.beginning_of_day + 19.hours
    render layout: false
  end

  def process_schedule_builder
    df, dt = params[:date_range].split(' - ')
    date_from = Chronic.parse(df).to_date
    date_to = Chronic.parse(dt).to_date
    cnt = 0
    date_from.upto(date_to).each do |date|
      if params[:dow].include? date.strftime('%w')
        params[:time_slot_time].each do |tst|
          time = Time.at(tst.to_i)
          dstring = "#{date.strftime('%F')}T#{time.strftime('%T')}"
          d = Chronic.parse(dstring)
          ts = TimeSlot.for_time(d).by_instructor(params[:instructor_id]).first_or_create({
            start_at: d,
            duration: 20,
            instructor_id: params[:instructor_id]
          })
          cnt += 1
        end
      end
    end
    redirect_to admin_schedule_path, notice: "Created #{cnt} time slots"
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

  def unassign_time_slot
    time_slot = TimeSlot.find(params[:id])
    if time_slot && time_slot.can_unassign?(current_user)
      time_slot.unassign_student!
      render json: { ok: true }
    else
      render json: { ok: false }
    end
  end

  def create_time_slot
    d = Chronic.parse(params[:date])
    ts = TimeSlot.for_time(d).by_instructor(params[:instructor_id]).first_or_create({
      start_at: d,
      duration: 20,
      instructor_id: params[:instructor_id]
    })
    render json: { ok: true }
  end

  def destroy_time_slot
    time_slot = TimeSlot.find(params[:id])
    d = time_slot.start_at.strftime('%F')
    if time_slot.deleteable?
      time_slot.destroy
      redirect_to scheduler_path(params: { date: d }), notice: 'Time slot was deleted'
    else
      redirect_to scheduler_path(params: { date: d }), alert: 'Cannot delete time slot'
    end
  end

  def resources
    resources = []
    User.instructor.each do |instructor|
      resources << {
        id: instructor.id,
        title: instructor.full_name
      }
    end
    render json: resources
  end

end
