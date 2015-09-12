class Admin::ReportsController < ApplicationController
  before_action :require_administrator

  def lessons
    @date_from = Time.current.beginning_of_day - 30.days
    @date_to = Time.current.end_of_day

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
end
