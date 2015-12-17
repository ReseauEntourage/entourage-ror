class EncounterReverseGeocodeJob < ActiveJob::Base

  def perform(encounter_id)
    return if Rails.env.test?

    encounter = Encounter.find(encounter_id)
    encounter.reverse_geocode
    encounter.save
  end
end