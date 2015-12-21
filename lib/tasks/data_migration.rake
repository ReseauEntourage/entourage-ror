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

  desc "geocode encounters"
  task geocode_encounters: :environment do
    Encounter.find_each do |encounter|
      EncounterReverseGeocodeJob.perform_now(encounter.id)
    end
  end

  desc "Hash all user sms_code"
  task hash_sms_code: :environment do
    User.find_each do |user|
      user.update_columns(sms_code: BCrypt::Password.create(user.sms_code)) if user.sms_code.length == 6
    end
  end

  desc "set dev organization"
  task set_dev_organization: :environment do
    org = Organization.create!(name: "dev only", description: "dev only", phone: "0123456789", address: "foobar")
    User.where(email: "vdaubry@gmail.com").first.update(organization: org)
  end

  desc "set default longitude and latitude"
  task set_default_longitude_and_latitude: :environment do
    User.find_each do |user|
      user_default = PreferenceServices::UserDefault.new(user: user)
      user_default.latitude = user.default_latitude
      user_default.longitude = user.default_longitude
    end
  end
end