class MigrateRpushToFcm < ActiveRecord::Migration[6.1]
  def up
    app = Rpush::Fcm::App.new
    app.name = "entourage"
    # app.firebase_project_id = "entourage-90011"
    # app.json_key = ENV['RPUSH_FCM_JSON_KEY']
    app.auth_key = ENV['RPUSH_FCM_JSON_KEY']
    app.environment = 'production'
    app.connections = 30
    app.save!
  end
end
