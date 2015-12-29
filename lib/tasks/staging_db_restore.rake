namespace :db do
  desc "Restore staging db from production"
  task restore_staging: :environment do
    generate_credential_file
    `sh #{File.dirname(File.dirname(__FILE__))}/../scripts/restore_staging_db.sh`
  end

  task remove_old_points: :environment do
    #Keep the latest 5000 tour points to stay below row limit
    last_id = TourPoint.reorder("id DESC").limit(5000).last.id
    TourPoint.where("id < #{last_id}").delete_all
    SnapToRoadTourPoint.delete_all
  end


  def generate_credential_file
    email = ENV["HEROKU_LOGIN"]
    password = ENV["HEROKU_PASSWORD"]
    template = ERB.new File.read("scripts/.netrc.erb")
    File.open(".netrc", "w") do |f|
      f.write(template.result(binding))
    end
  end
end