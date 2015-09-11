class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  mount_uploader :avatar, ::AvatarUploader

  has_many :students
  has_many :lessons
  has_many :orders
  has_many :time_slots, through: :students

  ROLES = %w[ admin instructor customer ]

  scope :instructor, -> { where("role = 'instructor' OR is_instructor = true") }

  validates :first_name, presence: true
  # validates :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  before_validation do
    self.phone = phone.gsub(/[^0-9]/, "") if attribute_present?('phone')
  end

  def self.instructors_for_date(date)
    instructor_ids = TimeSlot.by_date_range(date, date).map(&:instructor_id)
    User.where(id: instructor_ids).order('first_name asc')
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def admin?
    role == 'admin'
  end

  def instructor?
    role == 'instructor'
  end

  def customer?
    role == 'customer'
  end

  def future_time_slots
    cnt = 0
    students.each do |student|
      cnt += student.future_time_slots.count
    end
    cnt
  end

  def to_scheduler
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      avatar: avatar.thumb.url
    }
  end
end
