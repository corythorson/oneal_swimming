class CreateTimeSlots < ActiveRecord::Migration
  def change
    create_table :time_slots do |t|
      t.datetime :start_at, null: false
      t.integer :duration, null: false
      t.integer :instructor_id, null: false
      t.integer :student_id

      t.timestamps null: false
    end

    add_index :time_slots, :instructor_id
    add_index :time_slots, :student_id
  end
end
