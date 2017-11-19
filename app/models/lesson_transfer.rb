# == Schema Information
#
# Table name: lesson_transfers
#
#  id           :integer          not null, primary key
#  quantity     :integer          not null
#  user_id      :integer
#  recipient_id :integer          not null
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class LessonTransfer < ActiveRecord::Base
  has_paper_trail
  
  belongs_to :user
  has_many :lessons

  def recipient
    User.find(recipient_id)
  end
end
