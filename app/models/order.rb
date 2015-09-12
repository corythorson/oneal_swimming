class Order < ActiveRecord::Base
  has_many :lessons, dependent: :destroy

  def deleteable?
    lessons.unassigned.count == lessons.count
  end

  def self.create_from_paypal_response!(data)
    t = Time.current
    user_id, quantity = data['custom'].split(',')
    user = User.find(user_id)

    amount = data['mc_gross'].try(:to_f)
    amount ||= data['mc_gross1'].try(:to_f)

    if data['quantity1'].present?
      lessons = (data['quantity1'] || '1').to_i * quantity.to_i
    elsif data['quantity'].present?
      lessons = (data['quantity'] || '1').to_i * quantity.to_i
    else
      lessons = quantity.to_i
    end

    order = Order.create!(
      user_id: user.id,
      total: amount,
      quantity: lessons,
      merchant_response: data
    )

    lessons.times do
      if Lesson.where(order_id: order.id).count < lessons
        Lesson.create!(order_id: order.id, user_id: user_id, purchased_at: t, expires_at: t + 1.year)
      end
    end

    order
  end
end
