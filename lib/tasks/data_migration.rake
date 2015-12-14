namespace :data_migration do
  desc "Update phone format to +33"
  task phone_format: :environment do
    User.find_each do |user|
      phone_builder = Phone::PhoneBuilder.new(phone: user.phone)
      user.update(phone: phone_builder.format)
    end
  end

  desc "update tour types"
  test update_tour_types: :environment do
    Tour.where(type: "health").update_all(type: "medical")
    Tour.where(type: "friendly").update_all(type: "barehands")
    Tour.where(type: "social").update_all(type: "barehands")
    Tour.where(type: "food").update_all(type: "alimentary")
    Tour.where(type: "other").update_all(type: "medical")
  end
end