class EncounterReverseGeocodeJob
  # Use Sidekiq directly instead of ActiveJob for its better retry implementation
  # https://github.com/mperham/sidekiq/wiki/Active-Job#customizing-error-handling
  include Sidekiq::Worker

  def perform(encounter_id)
    return if Rails.env.test?

    encounter = Encounter.find(encounter_id)

    # this will raise in case of an API error
    # see config/initializers/geocoder.rb
    results = Geocoder.search(
      [encounter.latitude, encounter.longitude],
      language: :fr
    )

    best_result = results.find { |r| r.types.include? "point_of_interest" } ||
                  results.first

    return if best_result.nil?

    encounter.address = best_result.address
    encounter.save
  end

  # ActiveJob interface
  def self.perform_later(*args)
    perform_async(*args)
  end
end
