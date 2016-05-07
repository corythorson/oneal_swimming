class AddLessonTransferIdToLessons < ActiveRecord::Migration
  def change
    add_column :lessons, :lesson_transfer_id, :integer
  end
end
