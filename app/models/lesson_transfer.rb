class LessonTransfer < ActiveRecord::Base
  belongs_to :user
  has_many :lessons

  def recipient
    User.find(recipient_id)
  end
end
