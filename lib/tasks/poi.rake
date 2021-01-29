namespace :poi do
  # 0 - id
  # 2 - A actualiser
  # 3 - Date d'actualisation
  # 4 - Nom
  # 5 - Adresse
  # 6 - Public(s) bénéficiaire(s)
  # 7 - Description
  # 8 - Email
  # 9 - Téléphone
  # 10 - Site web
  # 11 - Catégorie 1
  # 12 - Catégorie 2
  # 13 - Catégorie 3
  # 14 - Catégorie 4
  # 15 - Catégorie 5
  # 16 - Catégorie 6
  # 17 - Catégorie 7
  desc "import poi.csv file"
  task import: :environment do
    CSV.read('docs/rennes.csv', headers: true).each do |row|
      row = row.to_hash.map { |k,v| [k, v&.strip] }.to_h # remove surrounding spaces or carriage returns

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
        audience: row['Public(s) bénéficiaire(s)'],
        validated: true
      }

      poi = Poi.new(attributes)
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
    mapping = {
      "Se nourrir" =>           1,
      "Se loger" =>             2,
      "Se soigner" =>           3,
      "Se rafraîchir" =>        4,
      "S'orienter" =>           5,
      "S'occuper de soi" =>     6,
      "Se réinsérer" =>         7,
      "Partenaires" =>          8,
      "Se déplacer" =>          9,
      "Toilettes" =>           40,
      "Fontaines" =>           41,
      "Douches" =>             42,
      "Laver son linge" =>     43,
      "Vêtements, matériel" => 61,
      "Boîtes à dons" =>       62,
      "Bagageries" =>          63,
    }

    categorie_names = [
      row['Catégorie 1'], row['Catégorie 2'], row['Catégorie 3'], row['Catégorie 4'], row['Catégorie5'], row['Catégorie 6'], row['Catégorie 7']
    ].reject(&:blank?)

    categorie_names.map do |category_name|
      mapping[category_name]
    end.reject(&:blank?)
  end
end
