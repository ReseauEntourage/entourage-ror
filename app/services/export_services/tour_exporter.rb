module ExportServices
  class TourExporter
    def initialize(tour:)
      @tour = tour
    end

    def new_csv(filename)
      name = filename.split(".")[0]
      ext = filename.split(".")[1]
      file = Tempfile.new([name, ".#{ext}"])
      @csv = CSV.open(file, "w+", :col_sep => ";", :encoding => 'UTF-8')
      yield(csv)
      csv.close
      file.path
    end

    def export_tour_points
      new_csv('tour_points.csv') do |csv|
        csv << ["latitude", "Longitude", "Date"]
        tour.tour_points.find_each do |tour_point|
          csv << [tour_point.latitude, tour_point.longitude, tour_point.passing_time]
        end
      end
    end

    def export_encounters
      new_csv('encounters.csv') do |csv|
        csv << ["Nom", "Addresse", "Notes", "latitude", "Longitude", "Date"]
        tour.encounters.find_each do |encounter|
          csv << [encounter.street_person_name, encounter.address, encounter.message, encounter.latitude, encounter.longitude, encounter.created_at]
        end
      end
    end

    private
    attr_reader :tour, :csv
  end
end
