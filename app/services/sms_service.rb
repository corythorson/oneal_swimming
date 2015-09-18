class SmsService

  SID = 'AC056da22789274ed6ad354bee7918246c' 
  TOKEN = '190e375ce9e1fd6bb6ab2a56df946dee' 
  
  def deliver_notifications
    client = Twilio::REST::Client.new SID, TOKEN

    date = Date.current + 1.day

    time_slots = TimeSlot.scheduled.by_date_range(date, date).order(:start_at)
    students = {}
    time_slots.each do |time_slot|
      students[time_slot.student_id] ||= []
      students[time_slot.student_id] << { time: time_slot.start_at.strftime('%I:%M %P'), instructor: time_slot.instructor.first_name }
    end

    students.each do |student_id, lessons|
      student = Student.find(student_id)
      user = student.user
      if user.phone
        message = "This is a reminder that #{student.first_name} has a swimming lesson tomorrow "
        lesson_messages = []
        lessons.each_with_index do |lesson, idx|
          if lessons.count > 1 && lessons.count == idx + 1
            lesson_messages << "and at #{lesson[:time]} with #{lesson[:instructor]}"
          else
            lesson_messages << "at #{lesson[:time]} with #{lesson[:instructor]}"
          end
        end
        message = message + lesson_messages.join(", ")
        client.account.messages.create({
          :from => '+18019198334',
          :to => '8015804496',
          :body => message
        })
      end
    end
  end
end
