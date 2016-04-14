class Order < ActiveRecord::Base
  has_many :lessons, dependent: :destroy
  belongs_to :user

  validates :remote_order_id, presence: true, uniqueness: { scope: [:user_id] }

  def deleteable?
    lessons.unassigned.count == lessons.count
  end

  def amount
    begin
      (merchant_response['amount'] / 100).to_f
    rescue
      total.to_f
    end
  end
end
