class AddIsActiveToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :is_active, :boolean, default: true
  end
end
