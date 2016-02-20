class ChargeCustomer
  class << self
    def call(user, product, params)
      Stripe.api_key = ENV['STRIPE_SECRET_KEY']

      # Get the credit card details submitted by the form
      token = params[:stripeToken]

      # Create a Stripe customer if it doesn't exist
      customer_id = user.stripe_customer_id || create_customer(user, token)

      # Create the charge on Stripe's servers - this will charge the user's card
      begin

        amount = product.stripe_amount
        quantity = product.quantity

        # Charge the Customer instead of the card
        charge = Stripe::Charge.create(
          amount: amount,
          currency: "usd",
          customer: customer_id,
          receipt_email: user.email,
          metadata: {
            user_id: user.id,
            product_name: product.name,
            product_id: product.id,
            profile_url: "http://utaquaticsacademy.com/profile/show/#{user.id}"
          }
        )

        order = OrderService.new.create_orders_and_lessons(user, product.price, quantity, charge)

        [order, nil]
      rescue Stripe::CardError => e
        # The card has been declined
        [nil, e]
      end
    end

    def create_customer(user, token)
      customer = Stripe::Customer.create(
        source: token,
        description: "#{user.full_name} <#{user.email}>"
      )
      user.update_attribute(:stripe_customer_id, customer.id)
      customer.id
    end
  end
end
