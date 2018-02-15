class ActionZone < ActiveRecord::Base
  belongs_to :user

  COUNTRIES = [
    { name: 'France',   code: 'FR', pc_length: 5 },
    { name: 'Belgique', code: 'BE', pc_length: 4 },
    { name: 'Suisse',   code: 'CH', pc_length: 4 },
  ]

  before_validation do
    code = Hash[COUNTRIES.map { |c| [c[:name], c[:code]] }]
    self.country = code[country] || country
  end

  validates :user_id, :country, :postal_code, presence: true
  validate :country do
    codes = COUNTRIES.map { |c| c[:code] }
    errors.add(:country, :inclusion) unless country.in?(codes)
  end
  validate :postal_code do
    expected = COUNTRIES.find { |c| c[:code] == country }
    if expected && postal_code.length != expected[:pc_length]
      errors.add(:postal_code, :wrong_length, count: expected[:pc_length])
    end
  end

  def country_name
    COUNTRIES.find { |c| c[:code] == country }.try(:[], :name)
  end
end
