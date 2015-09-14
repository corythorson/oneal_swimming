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

  task :reset_sequences => :environment do
    %w[ users products orders lessons students testimonials time_slots ].each do |table|
      cnt = ActiveRecord::Base.connection.query("SELECT MAX(id) FROM #{table}").flatten.first
      ActiveRecord::Base.connection.execute("SELECT setval('#{table}_id_seq', #{cnt})")
    end
    puts "DONE"
  end

  task :expiration_dates => :environment do
    Order.all.includes(:lessons).find_each do |order|
      order.lessons.each do |lesson|
        lesson.purchased_at = order.created_at
        lesson.expires_at = order.created_at + 1.year
        lesson.save
      end
      print "."
    end
    puts "DONE!"
    nil
  end
end