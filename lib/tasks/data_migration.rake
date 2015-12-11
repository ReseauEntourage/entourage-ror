namespace :data_migration do
  desc "Update phone format to +33"
  task phone_format: :environment do
    User.find_each do |user|
      phone_builder = Phone::PhoneBuilder.new(phone: user.phone)
      user.update(phone: phone_builder.format)
    end
  end
end