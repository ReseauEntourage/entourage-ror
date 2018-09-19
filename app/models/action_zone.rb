require 'geocoder/lookups/google_find_place_search'

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

  after_create :notify_user
  after_create :create_address

  def country_name
    COUNTRIES.find { |c| c[:code] == country }.try(:[], :name)
  end

  def self.create_address action_zone
    return unless action_zone.user.address.nil?

    result = Geocoder.search(
      "code postal #{action_zone.postal_code}",
      lookup: :google_find_place_search,
      params: {
        region: action_zone.country,
        fields: [
          'geometry/location',
          :name,
          :place_id
        ].join(',')
      }
    ).first

    return if result.nil?

    UserServices::AddressService.update_address(
      user: action_zone.user,
      params: {
        place_name: result.data['name'],

        latitude:  result.latitude,
        longitude: result.longitude,

        postal_code: action_zone.postal_code,
        country:     action_zone.country,

        google_place_id: result.place_id
      }
    )
  end

  def self.enable_address_conversion?
    !Rails.env.test?
  end

  private

  def notify_user
    MemberMailer.action_zone_confirmation(user, postal_code).deliver_later
  end

  def create_address
    return unless self.class.enable_address_conversion?
    AsyncService.new(self.class).create_address(self)
  end
end
