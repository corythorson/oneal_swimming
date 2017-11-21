class AddProductIdToLessons < ActiveRecord::Migration
  def change
    add_column :lessons, :product_id, :integer
  end
end
