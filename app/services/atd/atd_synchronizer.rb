module Atd
  class AtdSynchronizer

    class << self
      def synchronize
        files_to_synchronize.each do |filename|
          Rails.logger.info "Match user with export : #{filename}"
          tmp_file = Atd::AtdFtp.download_file(filename)
          Atd::CsvImporter.new(csv: tmp_file).match
          AtdSynchronization.create(filename: filename)
        end
      end

      def files_to_synchronize
        all_files = Atd::AtdFtp.list_files
        already_synchronize = AtdSynchronization.where(filename: all_files)
        all_files - already_synchronize
      end
    end

  end
end
