class AddLegacyIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :legacy_id, :integer
  end
end
