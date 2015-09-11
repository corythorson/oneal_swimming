class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.integer :user_id, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :avatar
      t.date :dob

      t.timestamps null: false
    end

    add_index :students, :user_id
  end
end
