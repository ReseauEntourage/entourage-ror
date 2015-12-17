namespace :data_migration do
  desc "Create ios Rpush app"
  task create_rpush_ios_app: :environment do
    Rpush::Apns::App.destroy_all

    app = Rpush::Apns::App.new
    app.name = "entourage"
    app.certificate = File.read File.join(Rails.root, 'certificates', 'ios_push_sandbox.pem')
    app.environment = "sandbox" # APNs environment.
    app.password = ""
    app.connections = 1
    app.save!
  end

  desc "Create ios Rpush app"
  task create_rpush_ios_app: :environment do
    Encounter.find_each do |encounter|
      EncounterReverseGeocodeJob.perform_now(encounter.id)
    end
  end
end