namespace :entourage do
  task set_entourage_user_suggestion: :environment do
    EntourageServices::UserEntourageSuggestion.perform
  end

  task set_entourage_score: :environment do
    puts "Starting set_entourage_score"
    EntourageServices::EntourageUserSuggestionsCalculator.compute
  end

  task generate_public_map_csv: :environment do
    entourages = Entourage
      .visible
      .where(group_type: [:action, :outing], community: :entourage)
      .where(created_at: 3.months.ago..Time.now)

    begin
      file = Tempfile.new(encoding: 'ascii-8bit') # binary mode
      gz = Zlib::GzipWriter.new(file)
      csv = CSV.new(gz)

      csv.puts [
        :latitude,
        :longitude,
        :title,
        :description,
        :creation_date,
        :author_name,
        :author_avatar_url,
        :status,
        :uuid,
        :uuid_v1
      ]

      entourages.includes(:user).find_each do |e|
        begin
          location_randomizer = EntourageServices::EntourageLocationRandomizer.new(entourage: e)
          csv.puts [
            location_randomizer.random_latitude.round(5),
            location_randomizer.random_longitude.round(5),
            e.title,
            e.description,
            e.created_at.iso8601,
            e.user.first_name,
            UserServices::Avatar.new(user: e.user).thumbnail_url,
            e.status,
            e.uuid_v2,
            e.uuid
          ]
        rescue => e
          Raven.capture_exception(e, extra: { entourage_id: e.id })
        end
      end

      gz.close
      file.close

      # e.g. https://entourage-csv.s3-eu-west-1.amazonaws.com/development/entourages.csv
      s3_bucket = Storage::Client.csv.send(:bucket)
      s3_object = s3_bucket.object("#{Rails.env}/entourages.csv")

      s3_object.upload_file(
        file.path,
        content_type: 'text/csv',
        content_encoding: 'gzip',
        acl: 'public-read',
      )

      puts s3_object.public_url
    ensure
      file.unlink
    end
  end
end
