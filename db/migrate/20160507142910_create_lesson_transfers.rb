class CreateLessonTransfers < ActiveRecord::Migration
  def change
    create_table :lesson_transfers do |t|
      t.integer :quantity, null: false
      t.references :user, index: true, foreign_key: true
      t.integer :recipient_id, null: false
      t.text :notes

      t.timestamps null: false
    end
  end
end
