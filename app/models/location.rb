# == Schema Information
#
# Table name: locations
#
#  id             :integer          not null, primary key
#  name           :string
#  street_address :string
#  city           :string
#  state          :string
#  zip_code       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slug           :string
#  is_active      :boolean          default(TRUE)
#

class Location < ActiveRecord::Base
  extend ::FriendlyId
  friendly_id :name, use: :slugged

  has_many :time_slots
  validates :name, presence: true, uniqueness: true
  validates :street_address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true

  scope :active, -> { where(is_active: true) }

  def full_address
    [street_address, city, state, zip_code].join(', ')
  end
end
