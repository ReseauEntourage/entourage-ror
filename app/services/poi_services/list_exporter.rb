module PoiServices
  class ListExporter
    DEFAULT_PATH = "#{Rails.root}/tmp"
    FIELDS = %w{
      id
      name
      adress
      description
      audience
      email
      website
      phone
      category_1
      category_2
      category_3
      category_4
      category_5
      category_6
      category_7
    }

    class << self
      def export poi_ids
        file = path

        CSV.open(file, 'w+') do |writer|
          writer << FIELDS.map { |field| I18n.t("activerecord.attributes.poi.#{field}") }

          poi_ids.each do |poi_id|
            poi = Poi.find(poi_id)
            writer << FIELDS.map { |field| poi.send(field) }
          end
        end

        file
      end

      def path
        "#{DEFAULT_PATH}/pois-#{Time.now.to_i}.csv"
      end
    end
  end
end
