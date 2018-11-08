# frozen_string_literal: true

namespace :db do
  namespace :check do
    desc "Check model's that have a number_of_people attribute"
    task nop: :environment do
      Rake::Task['db:check:entourage_nop'].invoke
      Rake::Task['db:check:tour_nop'].invoke
    end

    desc "Check Entourage's model number_of_people attribute"
    task entourage_nop: :environment do
      check_nop(Entourage)
    end

    desc "Check Tour's model number_of_people attribute"
    task tour_nop: :environment do
      check_nop(Tour)
    end

    def check_nop(model_class)
      model_class.all.each do |model|
        current_nop = model.number_of_people
        expected_nop = model.join_requests.select do |join_requests|
          join_requests.status == 'accepted'
        end.size

        next unless current_nop != expected_nop

        puts "#{model_class.name} #{model.id} has" \
          " current number_of_people of value #{current_nop}" \
          " expected number_of_people of value #{expected_nop}"
      end
    end
  end

  namespace :fix do

    desc "Fix model's that have a number_of_people attribute"
    task nop: :environment do
      Rake::Task['db:fix:entourage_nop'].invoke
      Rake::Task['db:fix:tour_nop'].invoke
    end

    desc "Fix Entourage's model number_of_people attribute"
    task entourage_nop: :environment do
      fix_nop(Entourage)
    end

    desc "Fix Tour's model number_of_people attribute"
    task tour_nop: :environment do
      fix_nop(Tour)
    end

    def fix_nop(model_class)
      model_class.all.each do |model|
        # nop -> numer_of_people
        current_nop = model.number_of_people
        expected_nop = model.join_requests.select do |join_requests|
          join_requests.status == 'accepted'
        end.size

        next unless current_nop != expected_nop

        model.number_of_people = expected_nop
        model.save
      end
    end
  end
end
