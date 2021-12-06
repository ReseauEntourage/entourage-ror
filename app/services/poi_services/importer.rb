module PoiServices
  class Importer
    def initialize(path:)
      @path = path
    end

    # Id
    # Nom
    # Adresse
    # Description
    # Public
    # Website
    # Téléphone
    # Catégorie1
    # Catégorie2
    # Catégorie3
    # Catégorie4
    # Catégorie5
    # Catégorie6
    # Catégorie7
    def import!
      CSV.read(path, headers: true).each do |row|
        row = row.to_hash.map { |k,v| [k, v&.strip] }.to_h # remove surrounding spaces or carriage returns

        attributes = {
          name: row['Nom'],
          adress: row['Adresse'],
          # we use different notation because of poi_geocoder specifications
          "adress" => row['Adresse'],
          description: row['Description'],
          audience: row['Public'],
          email: row['Email'],
          website: row['Website'],
          phone: row['Téléphone'],
          category_id: row['Catégorie1'],
          category_ids: [row['Catégorie1'], row['Catégorie2'], row['Catégorie3'], row['Catégorie4'], row['Catégorie5'], row['Catégorie6'], row['Catégorie7']].uniq.compact,

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

    private
    attr_reader :path
  end
end
