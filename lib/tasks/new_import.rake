require 'csv'

def import_from_csv!(table)
  ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
  ActiveRecord::Base.connection.execute("SELECT setval('#{table}', (SELECT MAX(id) FROM #{table}))")
  ActiveRecord::Base.connection.execute("COPY #{table} FROM '#{Rails.root.join('new_data', "#{table}.csv")}' DELIMITER ',' CSV HEADER")
end

def import_time_slots!
  ActiveRecord::Base.connection.execute("DELETE FROM time_slots")
  ActiveRecord::Base.connection.execute("SELECT setval('time_slots', (SELECT MAX(id) FROM time_slots))")
  CSV.foreach(Rails.root.join('new_data', 'time_slots.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    # id,start_at,duration,instructor_id,student_id,created_at,updated_at,legacy_id
    start_at = DateTime.strptime("#{row['start_at']}-06:00", '%m/%d/%Y %H:%M:%S%z') # 10/08/2015 12:40:00
    TimeSlot.create!({
        id: row['id'],
        start_at: start_at,
        duration: row['duration'],
        instructor_id: row['instructor_id'],
        student_id: row['student_id'],
        created_at: row['created_at'],
        updated_at: row['updated_at'],
        legacy_id: row['legacy_id']
      })
    print "."
    nil
  end
end

def import_lessons!
  ActiveRecord::Base.connection.execute("DELETE FROM lessons")
  ActiveRecord::Base.connection.execute("SELECT setval('lessons', (SELECT MAX(id) FROM lessons))")
  CSV.foreach(Rails.root.join('new_data', 'lessons.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    # id,user_id,order_id,purchased_at,expires_at,created_at,updated_at,time_slot_id
    lesson = Lesson.create!({
        id: row['id'],
        user_id: row['user_id'],
        order_id: row['order_id'],
        purchased_at: row['purchased_at'],
        expires_at: row['expires_at'],
        created_at: row['created_at'],
        updated_at: row['updated_at']
      })
    if row['time_slot_id'].present?
      TimeSlot.where(id: row['time_slot_id']).update_all("lesson_id = #{lesson.id}")
      print 'o'
    else
      print '.'
    end
    nil
  end
end

namespace :new_import do
  task :all => :environment do
    import_from_csv!('users')
    import_from_csv!('products')
    import_from_csv!('students')
    import_from_csv!('testimonials')
    import_time_slots!
    import_from_csv!('orders')
    import_lessons!
    puts "DONE!!!!"
  end

  task :users => :environment do
    import_from_csv!('users')
  end

  task :products => :environment do
    import_from_csv!('products')
  end

  task :students => :environment do
    import_from_csv!('students')
  end

  task :testimonials => :environment do
    import_from_csv!('testimonials')
  end

  task :time_slots => :environment do
    import_time_slots!
  end

  task :orders => :environment do
    import_from_csv!('orders')
  end

  task :lessons => :environment do
    import_lessons!
  end
end
