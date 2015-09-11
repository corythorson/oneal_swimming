require 'csv'

def random_password
  (0...8).map { (65 + rand(26)).chr }.join
end

def first_name(name)
  name.split.first
end

def last_name(name)
  if name.split.count > 1
    name.split[1..-1].join(' ')
  end
end

def import_users!
  CSV.foreach(Rails.root.join('data', 'User.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    email = row['Email'].downcase
    name = row['Name'].split(' ').map(&:titleize).join(' ')
    password = random_password
    begin
      user = User.where(email: email).first_or_initialize(
          first_name: first_name(name),
          last_name: last_name(name),
          phone: '',
          role: 'customer',
          password: password,
          password_confirmation: password,
          legacy_id: row['UserID']
        )
      user.save(validate: false)
      puts "[#{user.id}] #{user.full_name} - #{user.email}"
    rescue => ex
      puts ex.message
      puts row.inspect
    end
  end
end

def import_instructors!
  idx = 0
  num_to_string = {
    12 => "twelve",
    11 => "eleven",
    10 => "ten",
    9  => "nine",
    8  => "eight",
    7  => "seven",
    6  => "six",
    5  => "five",
    4  => "four",
    3  => "three",
    2  => "two",
    1  => "one"
  }
  CSV.foreach(Rails.root.join('data', 'Teacher.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    idx += 1
    email = "lane_#{idx}@utaquaticsacademy.com"
    fname = 'Lane'
    lname = num_to_string[idx].capitalize
    password = random_password
    begin
      user = User.where(email: email).first_or_initialize(
        first_name: fname,
        last_name: lname,
        phone: '',
        role: 'instructor',
        password: password,
        password_confirmation: password,
        legacy_id: row['TeacherID']
      )
      user.save(validate: false)
      puts "[#{user.id}] #{user.full_name} - #{user.email}"
    rescue => ex
      puts ex.message
      puts row.inspect
    end
  end
end

def import_learners!
  CSV.foreach(Rails.root.join('data', 'Student.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8', :quote_char => "~") do |row|
    user = User.where(legacy_id: row['UserID']).first
    legacy_id = row['StudentID']
    begin
      student = Student.where(legacy_id: legacy_id).first_or_initialize(
        user_id: user.id,
        first_name: row['Name'].present? ? row['Name'].scan(/[A-Za-z\s\']/).join.strip : 'Student',
        last_name: user.last_name,
        legacy_id: legacy_id
      )
      student.save(validate: false)
      puts "[#{student.id}] #{student.first_name}"
    rescue => ex
      puts ex.message
      puts row.inspect
    end
  end
end

def import_purchases!
  # PurchaseID,UserID,Time,Item,Price,NumLessons,PayPalTX
  CSV.foreach(Rails.root.join('data', 'Purchase.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    user = User.where(legacy_id: row['UserID']).first
    order = Order.where(legacy_id: row['PurchaseId']).first_or_initialize({
        user_id: user.id,
        total: row['Price'],
        quantity: row['NumLessons'],
        merchant_response: row.inspect,
        created_at: Time.at(row['Time'].to_i).in_time_zone,
        legacy_id: row['PurchaseID']
      })
    order.save(validate: false)
  end
end

def import_hours!
  TimeSlot.delete_all
  CSV.foreach(Rails.root.join('data', 'Hour.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    legacy_id = row['HourID']
    instructor = User.where(legacy_id: row['TeacherID']).where(role: 'instructor').first
    start_time = row['Start'].to_i
    end_time = row['End'].to_i - 1200
    # puts "-----"
    (start_time..end_time).step(1200).each do |ts|
      # puts Time.at(ts).in_time_zone.strftime('%H:%M')
      start_at = Time.at(ts).in_time_zone

      timeslot = TimeSlot.where(legacy_id: legacy_id).where(start_at: start_at).first_or_create!({
          start_at: start_at,
          duration: 20,
          instructor_id: instructor.id,
          student_id: nil
        })
      puts "[#{timeslot.id}] #{timeslot.start_at.strftime('%F %H:%M')}"
    end
  end
end

def import_lessons!
  CSV.foreach(Rails.root.join('data', 'Lesson.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
    #LessonID,TeacherID,StudentID,Time
    instructor = User.where(role: 'instructor').where(legacy_id: row['TeacherID']).first
    student = Student.where(legacy_id: row['StudentID']).first
    t = Time.at(row['Time'].to_i).in_time_zone
    time_slot = TimeSlot.where(instructor_id: instructor.id).where(start_at: t).first
    if time_slot
      time_slot.update_attribute(:student_id, student.id)
    else
      puts row.inspect
    end
  end
end

def create_lessons!
  User.all.each do |user|
    user.orders.each do |order|
      if order.quantity >= 1
        order.quantity.times do
          Lesson.create!({
              user_id: user.id,
              order_id: order.id,
              purchased_at: order.created_at,
              expires_at: order.created_at + 1.year
            })
        end
      else
        delete_count = order.quantity.abs
        user.lessons.order('created_at desc').limit(delete_count).destroy_all
      end
    end

    lessons = user.lessons.order('created_at asc').to_a
    user.time_slots.order('start_at asc').each do |time_slot|
      lesson = lessons.shift
      if lesson.present?
        lesson.update_attribute(:time_slot_id, time_slot.id)
      end
    end
    print "."
  end
end

namespace :import do
  desc 'Legacy'
  task :legacy => :environment do
    import_users!
    import_purchases!
    import_instructors!
    import_learners!
    import_hours!
    import_lessons!
  end

  task :users => :environment do
    import_users!
  end

  task :purchases => :environment do
    import_purchases!
  end

  task :instructors => :environment do
    import_instructors!
  end

  task :learners => :environment do
    import_learners!
  end

  task :hours => :environment do
    import_hours!
  end

  task :lessons => :environment do
    import_lessons!
  end

  task :create_lessons => :environment do
    create_lessons!
  end

  task :phone_numbers => :environment do
    CSV.foreach(Rails.root.join('data', 'User.csv'), headers: true, encoding: 'ISO-8859-1:UTF-8') do |row|
      email = row['Email'].downcase.strip
      begin
        user = User.where('LOWER(email) = ?', email).first
        user.phone = (row['Phone'] || '').gsub(/[^0-9]/, '')
        user.save(validate: false)
        print '.'
      rescue => ex
        puts ex.message
        puts row.inspect
      end
    end
  end

  task :fix_learner_names do
    Student.includes(:user).each do |student|
      if student.first_name.split.last == student.user.last_name
        student.first_name = student.first_name.split[0...-1].join(' ')
        student.save(validate: false)
      end
    end
  end
end
