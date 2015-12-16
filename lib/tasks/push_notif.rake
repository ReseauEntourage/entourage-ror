namespace :push do
  desc "Send a ios push"
  task ios: :environment do
    device_ids = [User.where(email: "vdaubry@gmail.com").first.device_id]
    IosNotificationService.new.send_notification("Expéditeur", "Objet", "Contenu du message", device_ids)
  end
end