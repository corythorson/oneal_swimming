class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.decimal :total, precision: 12, scale: 3
      t.integer :quantity
      t.json :merchant_response

      t.timestamps null: false
    end
  end
end
