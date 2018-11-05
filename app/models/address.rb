class Address < ActiveRecord::Base
  validates_presence_of :place_name, :latitude, :longitude

  has_one :user

  after_commit :mixpanel_sync

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
    !Rails.env.test?
  end

  def mixpanel_sync(synchronous: false)
    return unless self.class.enable_mixpanel_sync?
    return unless (['country', 'postal_code'] & previous_changes.keys).any?
    return unless [country, postal_code].all?(&:present?)
    AsyncService.new(MixpanelService).sync_address(self)
  end
end
