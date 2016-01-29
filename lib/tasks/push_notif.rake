namespace :push do
  desc "Send a ios push"
  task ios: :environment do
    device_ids = [User.where(email: "vdaubry@gmail.com").first.device_id]
    IosNotificationService.new.send_notification("Expéditeur", "Objet", "Contenu du message", device_ids)
  end

  desc "update sandbox certificates"
  task update_sandbox_certificates: :environment do
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
  end

  desc "update sandbox certificates"
  task update_production_certificates: :environment do
    desc "Create ios Rpush app"
    task create_rpush_ios_app: :environment do
      Rpush::Apns::App.destroy_all

      app = Rpush::Apns::App.new
      app.name = "entourage"
      app.certificate = File.read File.join(Rails.root, 'certificates', 'ios_push_production.pem')
      app.environment = "production" # APNs environment.
      app.password = ""
      app.connections = 1
      app.save!
    end
  end
end