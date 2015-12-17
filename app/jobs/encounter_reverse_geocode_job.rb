class EncounterReverseGeocodeJob < ActiveJob::Base

  def perform(encounter_id)
    Encounter.find(encounter_id).reverse_geocode unless Rails.env.test?
  end
end