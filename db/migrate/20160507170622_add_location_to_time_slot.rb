class AddLocationToTimeSlot < ActiveRecord::Migration
  def change
    add_column :time_slots, :location_id, :integer
    add_index :time_slots, :location_id
  end
end
