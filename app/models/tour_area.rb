class TourArea < ActiveRecord::Base
  AREA_STATUS = ['active', 'inactive']

  validates_presence_of [:area, :status, :email]
  validates_format_of :email, with: /@/
  validates_inclusion_of :status, in: AREA_STATUS
  validates :departement, numericality: { only_integer: true }, length: { in: 2..5 }

  scope :active, -> { where(status: :active) }

  def active?
    status.to_sym == :active
  end
end
