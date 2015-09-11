class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.integer :quantity
      t.decimal :price, precision: 6, scale: 3
      t.boolean :active
      t.text :paypal_button_code

      t.timestamps null: false
    end
  end
end
