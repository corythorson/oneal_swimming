class CreateLessons < ActiveRecord::Migration
  def change
    create_table :lessons do |t|
      t.integer :user_id
      t.integer :order_id
      t.datetime :purchased_at
      t.datetime :expires_at

      t.timestamps null: false
    end

    add_index :lessons, :user_id
    add_index :lessons, :order_id
  end
end
