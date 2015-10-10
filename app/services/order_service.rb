class OrderService

  def create_order_from_paypal_response(data)
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

    # Create free lesson if qualified
    if user.referral_free_lesson_order_id.blank? && user.referer_id.present? && lessons >= 10
      order_2 = Order.create!(
          user_id: user.id,
          total: 0.0,
          quantity: 1,
          merchant_response: { notes: 'Free lesson from referer signup' }
      )
      Lesson.create!(order_id: order_2.id, user_id: user.id, purchased_at: t, expires_at: t + 1.year)

      user.update_attribute(:referral_free_lesson_order_id, order_2.id)
      puts "Created a free lesson for #{user.full_name} (#{user.id})"

      referer = User.where(id: user.referer_id).first
      if referer
        order_3 = Order.create!(
          user_id: referer.id,
          total: 0.0,
          quantity: 1,
          merchant_response: { notes: "Free lesson from referring #{user.full_name}" }
        )
        Lesson.create!(order_id: order_3.id, user_id: referer.id, purchased_at: t, expires_at: t + 1.year)
        puts "Created a free lesson for #{referer.full_name} (#{referer.id})"

        Notification.free_lesson(referer, user).deliver_now
      end
    end

    order
  end
end