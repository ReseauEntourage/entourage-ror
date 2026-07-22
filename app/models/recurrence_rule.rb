class RecurrenceRule < ApplicationRecord
  FREQUENCIES = [:daily, :weekly, :monthly]

  belongs_to :created_by, class_name: 'User'
  has_many :scheduled_publications

  validates_inclusion_of :frequency, in: FREQUENCIES.map(&:to_s)
  validates_presence_of :ends_on

  def active?
    active
  end
end
