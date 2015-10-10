class AddReferralFreeLessonOrderIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referral_free_lesson_order_id, :integer
  end
end
