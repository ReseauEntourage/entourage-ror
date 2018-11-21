require 'tasks/number_of_people'

namespace :db do
  namespace :check do
    desc "Check model's that have a number_of_people attribute"
    task number_of_people: :environment do
      Rake::Task['db:check:entourage_number_of_people'].invoke
      Rake::Task['db:check:tour_number_of_people'].invoke
    end

    desc "Check Entourage's model number_of_people attribute"
    task entourage_number_of_people: :environment do
      NumberOfPeople.check_number_of_people(Entourage)
    end

    desc "Check Tour's model number_of_people attribute"
    task tour_number_of_people: :environment do
      NumberOfPeople.check_number_of_people(Tour)
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
      NumberOfPeople.fix_number_of_people(Entourage)
    end

    desc "Fix Tour's model number_of_people attribute"
    task tour_number_of_people: :environment do
      NumberOfPeople.fix_number_of_people(Tour)
    end
  end
end
