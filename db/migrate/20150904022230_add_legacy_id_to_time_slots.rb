class AddLegacyIdToTimeSlots < ActiveRecord::Migration
  def change
    add_column :time_slots, :legacy_id, :integer
  end
end
