class AddTimeSlotIdToLessons < ActiveRecord::Migration
  def change
    add_column :lessons, :time_slot_id, :integer
    add_index :lessons, :time_slot_id
  end
end
