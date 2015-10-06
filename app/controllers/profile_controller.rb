require 'icalendar/tzinfo'

class ProfileController < ApplicationController
  before_filter :authenticate_user!

  def show
    if params[:paypal] == '1'
      flash.now[:notice] = 'Payment has been successfully received. Lesson(s) have been added to your account'
    end

    @user = current_user
    if params[:id] && current_user.admin?
      @user = User.find(params[:id])
    end

    respond_to do |format|
      format.html
      format.json { render json: {
          id: @user.id,
          first_name: @user.first_name,
          last_name: @user.last_name,
          role: @user.role,
          avatar: @user.avatar.thumb.url,
          students: @user.students.map(&:to_simple_json),
          remaining_lessons: @user.lessons.unassigned.count
        }
      }
    end
  end

  def edit
    @user = current_user
    if params[:id] && current_user.admin?
      @user = User.find(params[:id])
    end
  end

  def update
    @user = current_user
    if params[:id] && current_user.admin?
      @user = User.find(params[:id])
    end
    if @user.update_attributes(user_params)
      redirect_to profile_path(id: @user.id), notice: 'Your profile has been updated successfully!'
    else
      flash.now[:alert] = @user.errors.full_messages.join(', ')
      render :edit
    end
  end

  def export_ical
    @user = current_user
    if params[:id] && current_user.admin?
      @user = User.find(params[:id])
    end
    cal = Icalendar::Calendar.new
    @user.time_slots.each do |ts|
      event_start = ts.start_at
      event_end = ts.start_at + ts.duration.minutes
      tzid = "America/Denver"
      tz = TZInfo::Timezone.get tzid
      timezone = tz.ical_timezone event_start
      cal.add_timezone timezone
      cal.event do |e|
        e.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => tzid
        e.dtend   = Icalendar::Values::DateTime.new event_end, 'tzid' => tzid
        e.summary = "#{ts.student.first_name} swimming lesson with #{ts.instructor.first_name}"
      end
    end
    cal.publish
    headers['Content-Type'] = "text/calendar; charset=UTF-8"
    headers['Content-Disposition'] = 'attachment; filename="swimming_schedule.ics"'
    render :text => cal.to_ical
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :avatar, :password, :password_confirmation)
  end
end
