class Notification < ApplicationMailer
  default from: 'noreply@utaquaticsacademy.com'

  def contact(name, email, message)
    mail(
      from: "#{name} <#{email}>",
      to: ['info@utaquaticsacademy.com'],
      subject: 'Email from Contact Page',
      body: message)
  end

  def lesson_transferred(lesson_transfer)
    message = <<-EOS.strip_heredoc
Hi #{lesson_transfer.recipient.first_name},

We just wanted to let you know that #{lesson_transfer.user.full_name} just transferred #{lesson_transfer.quantity} swimming lessons to your account.

Here is the reason they specified:

------------------------------------------------------------

#{lesson_transfer.notes}

------------------------------------------------------------

Thank you for supporting us!!!

The Aquatics Academy Team
http://www.utaquaticsacademy.com
https://www.facebook.com/Oneal.Aquatics.Utah

    EOS
    mail(
      from: "info@utaquaticsacademy.com",
      to: [lesson_transfer.recipient.email],
      bcc: ['eric@utaquaticsacademy.com'],
      subject: "#{lesson_transfer.user.full_name} has just transferred #{lesson_transfer.quantity} lessons to you!",
      body: message)
  end

  def free_lesson(user, referred_user)
    message = <<-EOS.strip_heredoc
Congratulations! You received a FREE lesson from Aquatics Academy.

Your friend #{referred_user.first_name} signed up and purchased lessons.

Thank you for supporting us!!!

The Aquatics Academy Team
http://www.utaquaticsacademy.com
https://www.facebook.com/Oneal.Aquatics.Utah

    EOS
    mail(
      from: "info@utaquaticsacademy.com",
      to: [user.email],
      subject: 'Congratulations! You received a FREE lesson!',
      body: message)
  end

end
