class Notification < ApplicationMailer
  default from: 'noreply@utaquaticsacademy.com'

  def contact(name, email, message)
    mail(
      from: "#{name} <#{email}>",
      to: ['info@utaquaticsacademy.com'],
      subject: 'Email from Contact Page',
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
