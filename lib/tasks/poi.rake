namespace :poi do
  desc "import poi.csv file"
  task import: :environment do
    CSV.foreach('resources/poi.csv') do |row|
      category = Category.where(name: categories[row[0]]).first!
      poi_params = {category_id: category.id, name: row[1], description: row[2], adress: row[3], phone: row[4], website: row[5], email: row[6], audience: row[7]}
      poi = Poi.new(poi_params)
      poi = PoiServices::PoiGeocoder.new(poi: poi, params: poi_params).geocode
      if poi.valid?
        Poi.where(name: row[1]).destroy_all
        puts "saving Poi at line #{$INPUT_LINE_NUMBER}"
        poi.save
      else
        puts "Couldn't save POI at line #{$INPUT_LINE_NUMBER} : #{poi.errors.full_messages}"
      end
      sleep(1)
    end
  end

  def categories
    {
        "SE NOURRIR" => "Se nourrir",
        "SE LOGER" => "Se loger",
        "SE SOIGNER" => "Se soigner",
        "S'ORIENTER" => "S'orienter",
        "S’OCCUPER DE SOI" => "S'occuper de soi",
        "SE RÉINSÉRER" => "Se réinsérer"
    }
  end
end
