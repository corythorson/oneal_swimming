class AddLessonsCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lessons_count, :integer
    User.all.each do |user|
      User.reset_counters(user.id, :lessons)
    end
  end
end
