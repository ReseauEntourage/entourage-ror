namespace :data_migration do
  desc "run all pending migration jobs"
  task migration_jobs: :environment do
    Rake::Task["initialize_encounter_counter_cache"].invoke
    Rake::Task["set_defaut_map_locations"].invoke
  end

  desc "create simplified tour points"
  task create_simplified_tour_points: :environment do
    Tour.find_each { |t| SimplifyTourPointsJob.perform_now(t.id) }
  end

  desc "initialize encounter counter_cache"
  task initialize_encounter_counter_cache: :environment do
    Tour.update_all("encounters_count=(SELECT count(*) FROM encounters WHERE encounters.tour_id=tours.id)")
  end

  desc "clean default locations"
  task set_defaut_map_locations: :environment do
    User.find_each do |user|
      pref = PreferenceServices::UserDefault.new(user: user)
      if pref.latitude < 1
        pref.latitude = user.default_latitude || 48.866051
        pref.longitude = user.default_longitude || 2.3565218
      end
    end
  end

  desc "set mandatory infos for all users"
  task set_mandatory_info: :environment do
    User.where("last_name IS NULL OR last_name = ''").update_all(last_name: "_")
    User.where("phone IS NULL").each do |user|
      user.update(phone: "+336#{99999999-user.id}")
    end
  end

  desc "set initial members for tours"
  task set_tour_members: :environment do
    ToursUser.destroy_all
    Tour.update_all(number_of_people: 0)
    Tour.find_each do |tour|
      ToursUser.create!(tour: tour, user: tour.user)
    end
  end

  desc "set initial members for tours"
  task set_simplified_tour_points_passing_time: :environment do
    Tour.joins(:simplified_tour_points).find_each do |tour|
      tour.simplified_tour_points.update_all(created_at: tour.created_at)
    end
  end
end