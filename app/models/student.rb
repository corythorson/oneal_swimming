class Student < ActiveRecord::Base
  mount_uploader :avatar, ::AvatarUploader

  belongs_to :user
  has_many :time_slots
  validates :first_name, presence: true

  def future_time_slots
    time_slots.where('start_at >= ?', Time.current)
  end

  def past_time_slots
    time_slots.where('start_at < ?', Time.current)
  end

  def to_simple_json
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      avatar: avatar.thumb.url,
      photo: avatar.url
    }
  end
end
