module RpushApp
  class Install
    def initialize
      @community = :entourage

      @environment ||= if EnvironmentHelper.production?
        :production
      else
        :development
      end

      @team_id = ENV['APNS8_TEAM_ID']
      @bundle_id = ENV['APNS8_BUNDLE_ID']
      @apn_key = ENV['APNS8_APN_KEY']
      @apn_key_id = ENV['APNS8_APN_KEY_ID']
    end

    def create_ios_apns8!
      app = Rpush::Apnsp8::App.new
      app.name = @community
      app.environment = @environment
      app.team_id = @team_id
      app.bundle_id = @bundle_id
      app.apn_key = @apn_key
      app.apn_key_id = @apn_key_id
      app.connections = 1
      app.save!
    end

    def delete_ios_apns8!
      Rpush::Apnsp8::App.where(name: @community).each do |app|
        app.destroy!
      end
    end
  end
end
