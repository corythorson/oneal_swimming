class Order < ActiveRecord::Base
  has_many :lessons, dependent: :destroy

  def deleteable?
    lessons.unassigned.count == lessons.count
  end
end
