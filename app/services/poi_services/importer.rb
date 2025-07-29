module PoiServices
  class Importer
    # Id
    # Nom
    # Adresse
    # Description
    # Public, Public(s) bénéficiaire(s)
    # Website
    # Téléphone
    # Catégorie1
    # Catégorie2
    # Catégorie3
    # Catégorie4
    # Catégorie5
    # Catégorie6
    # Catégorie7
    def self.import path
      read CSV.read(path, headers: true)
    end

    def self.read csv:
      successes = []
      errors = []

      csv.each do |row|
        row = row.to_hash.map { |k,v| [k, v&.strip] }.to_h # remove surrounding spaces or carriage returns

        attributes = {
          :name => row['Nom'],
          :adress => row['Adresse'],
          # we use different notation because of poi_geocoder specifications
          "adress" => row['Adresse'],
          :description => row['Description'],
          :audience => row['Public'] || row['Public(s) bénéficiaire(s)'],
          :email => row['Email'],
          :website => row['Website'],
          :phone => row['Téléphone'],
          :category_id => row['Catégorie1'] || row['Catégorie 1'],
          :category_ids => [
            row['Catégorie1'] || row['Catégorie 1'],
            row['Catégorie2'] || row['Catégorie 2'],
            row['Catégorie3'] || row['Catégorie 3'],
            row['Catégorie4'] || row['Catégorie 4'],
            row['Catégorie5'] || row['Catégorie 5'],
            row['Catégorie6'] || row['Catégorie 6'],
            row['Catégorie7'] || row['Catégorie 7']
          ].uniq.compact,
          :validated => true
        }

        poi = Poi.new(attributes)
        poi = PoiServices::PoiGeocoder.new(poi: poi, params: attributes).geocode

        if poi.valid?
          poi.save and successes << row['Nom']
        else
          errors << [row['Nom'], poi.errors.full_messages]
        end
      end

      yield successes, errors
    end
  end
end
