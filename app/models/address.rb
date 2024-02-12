class Address < ApplicationRecord
  include Onboarding::UserEventsTracking::AddressConcern
  include CoordinatesScopable

  USER_MAX_ADDRESSES = 2

  validates_presence_of :place_name, :latitude, :longitude, :user_id
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: USER_MAX_ADDRESSES }

  belongs_to :user

  after_save :set_user_address_id_if_primary!
  after_save :sync_salesforce

  def to_s
    display_address
  end

  def display_address
    [place_name, postal_code].compact.uniq.join(', ')
  end

  COUNTRIES = [
    { name: 'France',   code: 'FR' },
    { name: 'Belgique', code: 'BE' },
    { name: 'Suisse',   code: 'CH' },
  ]

  def country_name
    COUNTRIES.find { |c| c[:code] == country }.try(:[], :name) || country
  end

  def self.enable_mixpanel_sync?
    false
  end

  def mixpanel_sync(synchronous: false)
    return unless self.class.enable_mixpanel_sync?
    return unless (['country', 'postal_code'] & previous_changes.keys).any?
    return unless [country, postal_code].all?(&:present?)
    AsyncService.new(MixpanelService).sync_address(self)
  end

  def departement
    postal_code[0..1]
  end

  def paris?
    departement == '75'
  end

  def sync_salesforce
    SalesforceJob.perform_later(user_id, :upsert)
  end

  private

  def set_user_address_id_if_primary!
    return unless saved_change_to_position? || saved_change_to_user_id?
    user.update!(address_id: id) if position == 1
  end
end
