# == Schema Information
#
# Table name: orders
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  total             :decimal(12, 3)
#  quantity          :integer
#  merchant_response :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  legacy_id         :integer
#  remote_order_id   :string
#

class Order < ActiveRecord::Base
  has_paper_trail

  has_many :lessons, dependent: :destroy
  belongs_to :user

  validates :remote_order_id, presence: true, uniqueness: { scope: [:user_id] }

  scope :without_remote_order, -> { where(remote_order_id: nil) }
  scope :internally_created, -> { where("remote_order_id SIMILAR TO '[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}'") }
  scope :by_date_range, -> (d1, d2) { where('created_at >= ?', d1.beginning_of_day).where('created_at <= ?', d2.end_of_day) }

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

  def notes
    (merchant_response || {})["notes"]
  end
end
