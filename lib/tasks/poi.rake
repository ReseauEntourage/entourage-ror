namespace :poi do
  # 0 - Type (ignore)
  # 1 - Id (ignore)
  # 2 - Nom (string) name
  # 3 - Adresse (string) adress
  # 4 - Description (string) description
  # 5 - Public (string) audience
  # 6 - Email (string) email
  # 7 - website (string) website
  # 8 - Téléphone (string) phone
  # 9 - Catégorie (int) category_id
  # 10 - Date de création (ignore)
  desc "import poi.csv file"
  task import_bordeaux: :environment do
    CSV.read('docs/pois-bordeaux.csv', headers: true).each do |row|
      row = row.to_hash.map { |k,v| [k, v&.strip] }.to_h # remove surrounding spaces or carriage returns

      attributes = {
        name: row['Nom'],
        adress: row['Adresse'],
        # we use different notation because of poi_geocoder specifications
        "adress" => row['Adresse'],
        description: row['Description'],
        audience: row['Public'],
        email: row['Email'],
        website: row['website'],
        phone: row['Téléphone'],
        category_id: row['Catégorie'],

        validated: true
      }

      poi = Poi.new(attributes)
      poi = PoiServices::PoiGeocoder.new(poi: poi, params: attributes).geocode

      if poi.valid?
        puts "saving Poi #{row['Nom']}, #{row['Adresse']} (#{poi.latitude}, #{poi.longitude})"
        poi.save
      else
        puts "Couldn't save Poi : #{poi.errors.full_messages}"
      end
    end
  end
end
