class AddRemoteOrderIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :remote_order_id, :string
    add_index :orders, [:remote_order_id, :user_id], unique: true
  end
end
