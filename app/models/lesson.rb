class Lesson < ActiveRecord::Base
  belongs_to :user, counter_cache: true
  belongs_to :order
  belongs_to :time_slot

  scope :expired, -> { where('expires_at < ?', Time.now) }
  scope :not_expired, -> { where('expires_at >= ?', Time.now) }
  scope :assigned, -> { where.not(time_slot_id: nil) }
  scope :unassigned, -> { not_expired.where(time_slot_id: nil) }
  scope :completed, -> { assigned.join(:time_slot).where('"time_slots"."start_at" <= ?', Time.now) }
  scope :scheduled, -> { assigned.join(:time_slot).where('"time_slots"."start_at" > ?', Time.now) }

  def status
    if time_slot
      time_slot_at = time_slot.start_at
      if time_slot_at < Time.now.utc
        'completed'
      elsif expires_at < Time.now.utc
        'expired'
      else
        'scheduled'
      end
    else
      'unscheduled'
    end
  end
end
