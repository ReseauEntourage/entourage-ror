module ExportServices
  class DasboardExporter
    def initialize
      @book = Spreadsheet::Workbook.new
      @sheet1 = book.create_worksheet(name: "Derniers évènements")
    end

    def export
      csv = CSV.open("sample.csv", "w+", :col_sep => ";", :encoding => 'UTF-8')
      csv << ["Column 1", "Column 2", "Column 3"]
      csv << ["Value 1", "Value 2", "Value 3"]
      csv.close
    end

    def export_tour(tour:)

    end

    private
    attr_reader :book, :sheet1
  end
end
