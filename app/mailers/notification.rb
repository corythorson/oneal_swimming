class Notification < ApplicationMailer
  default from: 'noreply@utaquaticsacademy.com'

  def contact(name, email, message)
    mail(
      from: "#{name} <#{email}>",
      to: ['info@utaquaticsacademy.com', 'jod@utaquaticsacademy.com', 'alliesha@utaquaticsacademy.com', 'onealaquatics@hotmail.com', 'alliesha_oneal@yahoo.com'],
      bcc: ['amberry202@gmail.com'],
      subject: 'Email from Contact Page',
      body: message)
  end

end
