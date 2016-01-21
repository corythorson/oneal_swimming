module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction}, {:class => css_class}
  end

  def vertex_cart_button(user, product)
    price = number_with_precision(product.price, precision: 2)
    sku = "#{product.quantity}x#{price.gsub('.','')}"
    form = <<-EOS
<form action="https://vertexpayments.transactiongateway.com/cart/cart.php" method="POST">
  <input type="hidden" name="key_id" value="#{ENV['VERTEX_KEY_ID']}" />
  <input type="hidden" name="merchant_defined_field_1" value="#{user.id}" />
  <input type="hidden" name="action" value="process_cart" />
  <input type="hidden" name="product_sku_1" value="#{sku}" />
  <input type="hidden" name="product_description_1" value="#{product.name.gsub('"', "'")}" />
  <input type="hidden" name="product_amount_1" value="#{price}" />
  <input type="hidden" name="url_continue" value="#{ our_lessons_url }" />
  <input type="hidden" name="language" value="en" />
  <input type="hidden" name="url_cancel" value="#{ our_lessons_url }" />
  <input type="hidden" name="url_finish" value="#{ merchant_vertex_url }" />
  <input type="hidden" name="customer_receipt" value="true" />
  #{product.paypal_button_code.html_safe}
  <div class="input-group" style="max-width: 170px;">
    <input type="text" name="product_quantity_1" class="form-control col-xs-2" placeholder="Qty" value="1" />
    <span class="input-group-btn">
      <input type="submit" name="submit" value="Add to Cart" class="btn btn-success" />
    </span>
  </div>
</form>
    EOS
    form.html_safe
  end
end
