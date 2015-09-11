class Product < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def paypal_button(user_id)
    if paypal_button_code.present?
      paypal_button_code.gsub('CURRENT_USER_ID', user_id.to_s).html_safe
    end
  end
end
