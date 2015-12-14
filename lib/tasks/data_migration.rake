namespace :data_migration do
  desc "Update phone format to +33"
  task phone_format: :environment do
    User.find_each do |user|
      phone_builder = Phone::PhoneBuilder.new(phone: user.phone)
      user.update(phone: phone_builder.format)
    end
  end

  desc "update tour types"
  task update_tour_types: :environment do
    Tour.where(tour_type: "health").update_all(tour_type: "medical")
    Tour.where(tour_type: "friendly").update_all(tour_type: "barehands")
    Tour.where(tour_type: "social").update_all(tour_type: "barehands")
    Tour.where(tour_type: "food").update_all(tour_type: "alimentary")
    Tour.where(tour_type: "other").update_all(tour_type: "medical")
  end
end