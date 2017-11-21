class AddExpiresAfterMonthsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :expires_after_months, :integer, default: 12
  end
end
