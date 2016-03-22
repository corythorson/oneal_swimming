class AddIAgreeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :i_agree, :boolean, default: false
  end
end
