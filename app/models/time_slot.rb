class TimeSlot < ActiveRecord::Base
  belongs_to :instructor, class_name: 'User'
  belongs_to :student
  belongs_to :user
  belongs_to :lesson
  validates :instructor_id, presence: true

  scope :for_time, -> (t) { where('"time_slots"."start_at" = ?', t) }
  scope :by_date_range, -> (d1, d2) {
    where('"time_slots"."start_at" >= ?', d1.beginning_of_day).
    where('"time_slots"."start_at" <= ?', d2.end_of_day) }
  scope :by_instructor, -> (id) { where(instructor_id: id) }
  scope :scheduled, -> { where('start_at > ?', Time.current).where.not(student_id: nil) }

  def available?
    student_id.blank?
  end

  def can_unassign?(current_user)
    current_user.admin? || current_user.students.map(&:id).include?(student_id)
  end

  def assign_student(student, lesson)
    update_attributes({
        student_id: student.id,
        lesson_id: lesson.id
      })
  end

  def unassign_student!
    update_attributes({
        student_id: nil,
        lesson_id: nil
      })
  end

  def td_class(current_user_id)
    if student
      if student.user.id == current_user_id
        'time-slot-my-student'
      elsif student.first_name == 'Break'
        'time-slot-off'
      end
    else
      'time-slot-on'
    end
  end

  def cancelable?
    start_at >= Time.current + 24.hours
  end

  def deleteable?
    student_id.blank?
  end

  def to_react_event
    if student
      if student.first_name == 'Break'
        nil
      else
        {
          id: id,
          instructor_id: instructor.id,
          start: start_at.strftime('%FT%T'),
          end: (start_at + duration.minutes).strftime('%FT%T'),
          student: {
            id: student.id,
            user_id: student.user.id,
            first_name: student.first_name,
            last_name: student.user.last_name,
            avatar: student.avatar.thumb.url,
            parent_name: student.user.first_name
          }
        }
      end
    else
      {
        id: id,
        instructor_id: instructor.id,
        start: start_at.strftime('%FT%T'),
        end: (start_at + duration.minutes).strftime('%FT%T'),
        student: nil
      }
    end
  end
end
