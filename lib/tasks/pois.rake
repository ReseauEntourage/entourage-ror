namespace :pois do
  desc "Synchronize Soliguide into Entourage database"
  task synchronize_soliguide: :environment do
    PoiServices::SoliguideImporter.new.create_all
  end
end
