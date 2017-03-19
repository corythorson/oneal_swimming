class AddHiddenFieldsToInstructors < ActiveRecord::Migration
  def change
    add_column :users, :is_private_instructor, :boolean, default: false
    add_column :users, :instructor_invite_code, :string
    add_column :users, :private_instructor_ids, :text, array: true, default: []
  end
end
