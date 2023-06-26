namespace :push do
  desc "Send a ios push"
  task :ios, [:token] => [:environment] do |t, args|
    device_ids = [args[:token]]
    puts "device_ids = #{device_ids}"
    IosNotificationService.new.send_notification("Expéditeur", "Objet", "Contenu du message", device_ids, $server_community.slug)
  end

  task :android, [:token] => [:environment] do |t, args|
    device_ids = [args[:token]]
    puts "device_ids = #{device_ids}"
    AndroidNotificationService.new.send_notification("Expéditeur", "Objet", "Contenu du message", device_ids, $server_community.slug)
  end

  desc "create ios sandbox push app"
  task create_ios_sandbox_app: :environment do
    app = Rpush::Apns::App.new
    app.name = "entourage"
    app.certificate = File.read File.join(Rails.root, 'certificates', 'ios_push_sandbox.pem')
    app.environment = "sandbox" # APNs environment.
    app.password = ""
    app.connections = 1
    app.save!
  end

  desc "create ios production push app"
  task create_ios_production_app: :environment do
    app = Rpush::Apns::App.new
    app.name = "entourage"
    app.certificate = File.read File.join(Rails.root, 'certificates', 'ios_push_production.pem')
    app.environment = "production" # APNs environment.
    app.password = ""
    app.connections = 1
    app.save!
  end

  desc "create android push app"
  task create_android_production_app: :environment do
    Rpush::Gcm::App.destroy_all

    app = Rpush::Gcm::App.new
    app.name = "entourage"
    app.auth_key = "AIzaSyAOediRh9oYDQkIs0lkMcN_639sawoxCAg"
    app.connections = 1
    app.save!
  end

  desc "deliver_welcome"
  task deliver_welcome: :environment do
    Onboarding::TimelineDelivery.deliver_welcome
  end

  desc "deliver_on(2)"
  task deliver_on_2: :environment do
    Onboarding::TimelineDelivery.deliver_on(2)
  end

  desc "deliver_on(5)"
  task deliver_on_5: :environment do
    Onboarding::TimelineDelivery.deliver_on(5)
  end

  desc "deliver_on(8)"
  task deliver_on_8: :environment do
    Onboarding::TimelineDelivery.deliver_on(8)
  end

  desc "deliver_on(11)"
  task deliver_on_11: :environment do
    Onboarding::TimelineDelivery.deliver_on(11)
  end
end
