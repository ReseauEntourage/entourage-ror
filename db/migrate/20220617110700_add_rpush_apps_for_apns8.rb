class AddRpushAppsForApns8 < ActiveRecord::Migration[5.2]
  def up
    unless EnvironmentHelper.test?
      RpushApp::Install.new.create_ios_apns8!
    end
  end

  def down
    unless EnvironmentHelper.test?
      RpushApp::Install.new.delete_ios_apns8!
    end
  end
end
