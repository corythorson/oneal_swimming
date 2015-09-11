class Notification < ApplicationMailer
  default from: 'noreply@utaquaticsacademy.com'

  def contact(name, email, message)
    mail(
      from: "#{name} <#{email}>",
      to: 'info@utaquaticsacademy.com',
      subject: 'Email from Contact Page',
      body: message)
  end

end
