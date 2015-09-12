class Lesson < ActiveRecord::Base
  belongs_to :user, counter_cache: true
  belongs_to :order
  has_one :time_slot

  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :not_expired, -> { where('expires_at >= ?', Time.current) }
  scope :assigned, -> { includes(:time_slot).where.not(time_slots: { id: nil }) }
  scope :unassigned, -> { not_expired.includes(:time_slot).where(time_slots: { id: nil }) }
  scope :completed, -> { assigned.includes(:time_slot).where('"time_slots"."start_at" <= ?', Time.current) }
  scope :scheduled, -> { assigned.includes(:time_slot).where('"time_slots"."start_at" > ?', Time.current) }

  def status
    if time_slot
      time_slot_at = time_slot.start_at
      if time_slot_at < Time.current
        'completed'
      elsif expires_at < Time.current
        'expired'
      else
        'scheduled'
      end
    else
      'unscheduled'
    end
  end
end
