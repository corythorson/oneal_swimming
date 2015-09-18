class AddOfferCodeToProducts < ActiveRecord::Migration
  def change
    add_column :products, :offer_code, :string
  end
end
