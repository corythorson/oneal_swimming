namespace :fix do
  task :orphan_lessons => :environment do
    Lesson.where.not(time_slot_id: nil).find_each do |lesson|
      if lesson.time_slot.nil?
        lesson.update_attribute(:time_slot_id, -1)
      end
    end; puts "."

    TimeSlot.where.not(student_id: nil).includes(student: [:user]).find_each do |time_slot|
      user = time_slot.student.user
      lesson = Lesson.where(time_slot_id: time_slot.id).first
      unless lesson
        lesson = user.lessons.where(time_slot_id: -1).order('created_at asc').first
        if lesson
          lesson.update_attribute(:time_slot_id, time_slot.id)
        end
      end
    end; puts "."

    Lesson.where(time_slot_id: -1).each do |lesson|
      lesson.update_attribute(:time_slot_id, nil)
    end; puts "."

    puts "Finished"
  end
end