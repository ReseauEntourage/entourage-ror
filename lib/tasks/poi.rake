namespace :poi do
  # id ,Nom,Adresse,Adresse,Public(s) bénéficiaire(s),Description,Email,Téléphone,Site web,Catégorie 1,Catégorie 2,Catégorie 3,Catégorie 4,Catégorie 5,Catégorie 6,Catégorie 7
  desc "import poi.csv file"
  task import: :environment do
    CSV.read('docs/rennes.csv', headers: true).each do |row|
      category_ids = category_ids_from_row(row)

      attributes = {
        category_id: category_ids.first,
        category_ids: category_ids,
        name: row['Nom'],
        description: row['Description'],
        adress: row['Adresse'],
        # we use different notation because of poi_geocoder specifications
        "adress" => row['Adresse'],
        phone: row['Téléphone'],
        website: row['Site web'],
        email: row['Email'],
        audience: row['Public(s) bénéficiaire(s)']
      }

      if row['id'].present? && Poi.find_by_id(row['id'])
        poi = Poi.find(row['id'])
        poi.assign_attributes(attributes)
      else
        poi = Poi.new(attributes)
      end

      poi = PoiServices::PoiGeocoder.new(poi: poi, params: attributes).geocode

      if poi.valid?
        puts "saving Poi"
        poi.save
      else
        puts "Couldn't save Poi : #{poi.errors.full_messages}"
      end
      sleep(1)
    end
  end

  def category_ids_from_row row
    categorie_names = [
      row['Catégorie 1'], row['Catégorie 2'], row['Catégorie 3'], row['Catégorie 4'], row['Catégorie5'], row['Catégorie 6'], row['Catégorie 7']
    ].reject(&:blank?)

    categories = categorie_names.map do |category_name|
      Category.find_by_name(category_name)
    end.reject(&:blank?)

    categories.map(&:id)
  end
end
