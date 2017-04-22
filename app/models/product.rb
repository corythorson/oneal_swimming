class Product < ActiveRecord::Base
  has_paper_trail
  
  validates :name, presence: true, uniqueness: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def stripe_amount
    (price * 100).to_i
  end

  def paypal_button(user)
    if paypal_button_code.present?
      paypal_button_code
        .gsub('CURRENT_USER_ID', user.id.to_s)
        .gsub('CURRENT_USER_FIRST_NAME', user.first_name.to_s)
        .gsub('CURRENT_USER_LAST_NAME', user.last_name.to_s)
        .gsub('CURRENT_USER_EMAIL', user.email.to_s)
        .html_safe
    end
  end
end
