namespace :data_migration do
  desc "copy push token to application table"
  task set_user_applications_device_family: :environment do
    UserApplication.find_each do |user|
      device_os = (user.device_type == :android) ? "android" : "ios"
      user.user_applications.create(push_token: user.device_id,
                                    device_os: device_os,
                                    version: "1.0")
    end
  end
end