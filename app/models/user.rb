require 'csv'

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

  ROLES = %w[ admin instructor customer disabled ]

  attr_accessor :skip_i_agree

  scope :instructor, -> { where("role = 'instructor' OR is_instructor = true") }
  scope :customer, -> { where("role = 'customer'") }

  validates :first_name, presence: true
  # validates :last_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :i_agree, acceptance: { accept: true, message: 'must be checked prior to registering.' },
                      unless: Proc.new { |u| !!u.skip_i_agree }

  before_validation do
    self.phone = phone.gsub(/[^0-9]/, "") if attribute_present?('phone')
  end

  def self.instructors_for_date(date)
    instructor_ids = TimeSlot.by_date_range(date, date).map(&:instructor_id)
    User.where(id: instructor_ids).order('first_name asc')
  end

  def self.stale_customers
    User.customer.includes(:lessons).where(:lessons => { id: nil }).where(sign_in_count: 0)
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

  def discrepancy?
    lessons.count != orders.sum(:quantity)
  end

  def referer
    User.where(id: referer_id).first
  end

  def to_scheduler
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      avatar: avatar.thumb.url
    }
  end

  # Update password saving the record and clearing token. Returns true if
  # the passwords are valid and the record was saved, false otherwise.
  def reset_password(new_password, new_password_confirmation)
    self.password = new_password
    self.password_confirmation = new_password_confirmation

    # do not require i_agree to be checked for password resets
    self.skip_i_agree = true

    if respond_to?(:after_password_reset) && valid?
      ActiveSupport::Deprecation.warn "after_password_reset is deprecated"
      after_password_reset # from devise
    end

    save
  end

  def self.to_csv
    attributes = %w{id email sign_in_count first_name last_name phone created_at lessons_count }

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |user|
        csv << attributes.map{ |attr| user.send(attr) }
      end
    end
  end
end
