module Api
  module V1
    class CsvMatchingController < Api::V1::BaseController
      skip_before_action :authenticate_user!
      http_basic_authenticate_with name: ENV["ATD_USERNAME"], password: ENV["ATD_PASSWORD"]

      def show
        csv_file = Atd::CsvImporter.new(csv: input_csv).match
        cvs_bucket.upload(file: csv_file, key: filename)
        render text: cvs_bucket.url_for(key: filename)
      end

      private
      def input_csv
        open(params["url"])
      end

      def cvs_bucket
        Storage::Client.csv
      end

      def filename
        @filename ||= SecureRandom.uuid
      end
    end
  end
end
