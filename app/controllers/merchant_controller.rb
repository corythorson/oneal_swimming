class MerchantController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def ipn
    parms = { cmd: '_notify-validate' }
    params.each { |k, v| parms[k] = v }

    paypal_url = Rails.env.production? ? "https://www.paypal.com/cgi-bin/webscr" : "https://www.sandbox.paypal.com/cgi-bin/webscr"
    response = RestClient.post paypal_url, parms

    if response.body == 'VERIFIED'
      OrderService.new.create_order_from_paypal_response(params)
      render json: { accepted: true }
    else
      render json: { accepted: false, error: 'NOT A VALID REQUEST' }
    end
  end
end

# IPN Response
# {
#   "address_city": "San Jose",
#   "address_country": "United States",
#   "address_country_code": "US",
#   "address_name": "John Smith",
#   "address_state": "CA",
#   "address_status": "confirmed",
#   "address_street": "123 any street",
#   "address_zip": "95131",
#   "business": "seller@paypalsandbox.com",
#   "custom": "1,1",
#   "first_name": "John",
#   "invoice": "abc1234",
#   "item_name1": "Swimming Lesson",
#   "item_number1": "00001",
#   "last_name": "Smith",
#   "mc_currency": "USD",
#   "mc_fee": "0.44",
#   "mc_gross": "12.34",
#   "mc_gross1": "18.44",
#   "mc_handling": "0",
#   "mc_handling1": "0",
#   "mc_shipping": "0",
#   "mc_shipping1": "0",
#   "notify_version": "2.1",
#   "payer_email": "buyer@paypalsandbox.com",
#   "payer_id": "TESTBUYERID01",
#   "payer_status": "verified",
#   "payment_date": "Sat Aug 29 2015 21:23:28 GMT-0600 (MDT)",
#   "payment_status": "Completed",
#   "payment_type": "instant",
#   "quantity": "1",
#   "receiver_email": "seller@paypalsandbox.com",
#   "receiver_id": "seller@paypalsandbox.com",
#   "residence_country": "US",
#   "tax": "0",
#   "test_ipn": "1",
#   "txn_id": "200176850",
#   "txn_type": "cart",
#   "verify_sign": "AFcWxV21C7fd0v3bYYYRCpSSRl31ALWCudrnu0mw3vdinfJNrLc87Wr."
# }
