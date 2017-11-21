# == Schema Information
#
# Table name: testimonials
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  body       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Testimonial < ActiveRecord::Base
  validates :name, presence: true
  validates :body, presence: true
end
