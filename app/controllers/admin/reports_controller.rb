class Admin::ReportsController < ApplicationController
  before_action :require_administrator

  def lessons
    load_dates

    @lesson_data = []
    @lesson_data << {
      value: Lesson.completed.count,
      color: "#FDB45C",
      highlight: "#FFC870",
      label: "Completed"
    }
    @lesson_data << {
      value: Lesson.scheduled.count,
      color: "#46BFBD",
      highlight: "#5AD3D1",
      label: "Scheduled"
    }
    @lesson_data << {
      value: Lesson.unassigned.count,
      color: "rgba(26, 151, 147, 1)",
      highlight: "rgba(26, 151, 147, 0.8)",
      label: "Unscheduled"
    }
    @lesson_data << {
      value: Lesson.unassigned.expired.count,
      color:"#F7464A",
      highlight: "#FF5A5E",
      label: "Expired"
    }

    labels = []
    purchased_lessons = []
    (@date_from.to_i..@date_to.to_i).step(60*60*24).each do |d|
      dt = Time.at(d)
      labels << dt.strftime('%m/%d')
      purchased_lessons << Order.where('created_at >= ?', dt.beginning_of_day).where('created_at <= ?', dt.end_of_day).sum(:quantity)
    end

    @order_data = {
      labels: labels,
      datasets: [
        {
          label: "Purchased Lessons",
          fillColor: "rgba(0, 183, 240, 0.5)",
          strokeColor: "rgba(0, 183, 240, 1)",
          pointColor: "rgba(0, 183, 240, 1)",
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: "rgba(0, 183, 240, 1)",
          data: purchased_lessons
        }
      ]
    }
  end

  def instructor_lessons
    load_dates
    @data = {}
    User.instructor.order(:first_name).each do |instructor|
      time_slots = TimeSlot.by_time_range(@date_from, @date_to).by_instructor(instructor.id).where.not(student_id: nil)
      if time_slots.count > 0
        @data[instructor.full_name] = time_slots.count
      end
    end
  end

  private

  def load_dates
    fmt = '%m/%d/%Y'
    if params[:date_from].present? && params[:date_from] =~ /\d{4}-\d{2}-\d{2}/
      fmt = '%F'
    end

    begin
      if params[:date_from].present?
        params[:date_from] = DateTime.strptime(params[:date_from], fmt).strftime('%F')
      else
        params[:date_from] = Date.current.strftime('%F')
      end
    rescue
      params[:date_from] = Date.current.strftime('%F')
    end

    begin
      if params[:date_to].present?
        params[:date_to] = DateTime.strptime(params[:date_to], fmt).strftime('%F')
      else
        params[:date_to] = Date.current.strftime('%F')
      end
    rescue
      params[:date_to] = Date.current.strftime('%F')
    end

    @date_from = DateTime.strptime("#{params[:date_from]}T00:00:00#{Time.zone.now.formatted_offset}") || Time.current.beginning_of_day
    @date_to = DateTime.strptime("#{params[:date_to]}T23:59:59#{Time.zone.now.formatted_offset}") || Time.current.end_of_day
  end

end
