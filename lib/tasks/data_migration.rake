namespace :data_migration do
  task create_atd_partner: :environment do
    Partner.destroy_all
    Partner.create!(name: "ATD Quart Monde",
                    "large_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/ATDQM-coul-V-fr.png",
                    "small_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/Badge+image.png")
  end

  desc "set uuid to entourages"
  task set_uuid_to_entourages: :environment do
    Entourage.all.each do |entourage|
      entourage.update_attribute(:uuid, SecureRandom.uuid)
    end
  end
end
