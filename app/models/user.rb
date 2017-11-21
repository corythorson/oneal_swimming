# == Schema Information
#
# Table name: users
#
#  id                            :integer          not null, primary key
#  email                         :string           default(""), not null
#  encrypted_password            :string           default(""), not null
#  reset_password_token          :string
#  reset_password_sent_at        :datetime
#  remember_created_at           :datetime
#  sign_in_count                 :integer          default(0), not null
#  current_sign_in_at            :datetime
#  last_sign_in_at               :datetime
#  current_sign_in_ip            :inet
#  last_sign_in_ip               :inet
#  first_name                    :string
#  last_name                     :string
#  phone                         :string
#  role                          :string           default("customer")
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  provider                      :string
#  uid                           :string
#  profile                       :text
#  avatar                        :string
#  legacy_id                     :integer
#  lessons_count                 :integer
#  is_instructor                 :boolean          default(FALSE)
#  referer_id                    :integer
#  referral_free_lesson_order_id :integer
#  stripe_customer_id            :string
#  i_agree                       :boolean          default(FALSE)
#  braintree_customer_id         :string
#  is_private_instructor         :boolean          default(FALSE)
#  instructor_invite_code        :string
#  private_instructor_ids        :text             default([]), is an Array
#

require 'csv'

class User < ActiveRecord::Base
  has_paper_trail
  
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
  has_many :lesson_transfers

  ROLES = %w[ admin instructor customer disabled ]

  attr_accessor :skip_i_agree

  scope :instructor, -> { where("role = 'instructor' OR (is_instructor = true AND role != 'disabled')") }
  scope :customer, -> { where("role = 'customer'") }
  scope :private_instructor, -> { where(is_private_instructor: true) }

  validates :first_name, presence: true
  # validates :last_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :i_agree, acceptance: { accept: true, message: 'must be checked prior to registering.' },
                      unless: Proc.new { |u| !!u.skip_i_agree }

  before_validation do
    self.phone = phone.gsub(/[^0-9]/, "") if attribute_present?('phone')
  end

  def self.instructors_for_date(date, location)
    instructor_ids = location.time_slots.by_date_range(date, date).pluck(:instructor_id)
    User.where(id: instructor_ids).order('first_name asc')
  end

  def instructors_for_date(date, location)
    instructor_ids = location.time_slots.by_date_range(date, date).pluck(:instructor_id)
    available_instructor_ids = instructor_ids & instructors.pluck(:id)
    ::User.where(id: available_instructor_ids)
  end

  def self.stale_customers
    User.customer.includes(:lessons).where(:lessons => { id: nil }).where(sign_in_count: 0)
  end

  def transfers
    LessonTransfer.where("user_id = ? OR recipient_id = ?", id, id)
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

  def instructors
    if private_instructor_ids.present?
      ::User.instructor.where("is_private_instructor = false OR id IN (#{private_instructor_ids.join(',')})")
    else
      ::User.instructor.where(is_private_instructor: false)
    end
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
