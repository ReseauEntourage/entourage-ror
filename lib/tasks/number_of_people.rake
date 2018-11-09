namespace :db do

  # Execute given block on non-valid rows
  def on_differing_rows(model_class)
    batch_size = ENV['BATCH_SIZE'] || 100

    model_class.all.find_each(batch_size: batch_size) do |model|
      current_number_of_people = model.number_of_people
      expected_number_of_people = model.join_requests.where(status: 'accepted').count

      next unless current_number_of_people != expected_number_of_people

      yield(model, current_number_of_people, expected_number_of_people) if block_given?
    end
  end

  namespace :check do
    desc "Check model's that have a number_of_people attribute"
    task number_of_people: :environment do
      Rake::Task['db:check:entourage_number_of_people'].invoke
      Rake::Task['db:check:tour_number_of_people'].invoke
    end

    desc "Check Entourage's model number_of_people attribute"
    task entourage_number_of_people: :environment do
      check_number_of_people(Entourage)
    end

    desc "Check Tour's model number_of_people attribute"
    task tour_number_of_people: :environment do
      check_number_of_people(Tour)
    end

    def check_number_of_people(model_class)
      on_differing_rows(model_class) do |model, current_number_of_people, expected_number_of_people|
        puts "#{model_class.name} #{model.id} has" \
          " current number_of_people of value #{current_number_of_people}" \
          " expected number_of_people of value #{expected_number_of_people}"
      end
    end
  end

  namespace :fix do

    desc "Fix model's that have a number_of_people attribute"
    task number_of_people: :environment do
      Rake::Task['db:fix:entourage_number_of_people'].invoke
      Rake::Task['db:fix:tour_number_of_people'].invoke
    end

    desc "Fix Entourage's model number_of_people attribute"
    task entourage_number_of_people: :environment do
      fix_number_of_people(Entourage)
    end

    desc "Fix Tour's model number_of_people attribute"
    task tour_number_of_people: :environment do
      fix_number_of_people(Tour)
    end

    def fix_number_of_people(model_class)
      on_differing_rows(model_class) do |model, _, expected_number_of_people|
        model.update_column(:number_of_people, expected_number_of_people)
      end
    end
  end
end
