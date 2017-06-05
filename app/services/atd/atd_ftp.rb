require 'net/ftp'

module Atd
  class AtdFtp

    class << self
      def list_files
        ftp_conn do |ftp|
          ftp.nlst.reject { |f| [".", "..", "atd_entourage_20170410_complet.csv"].include? f }
        end
      end

      def download_file(filename)
        tmp = Tempfile.new(filename)
        ftp_conn do |ftp|
          ftp.gettextfile(filename, tmp.path)
        end
        tmp
      end

      private
      def ftp_conn
        Net::FTP.open('ftp.atd.odns.fr', ENV['ATD_USERNAME'], ENV['ATD_PASSWORD']) do |ftp|
          ftp.chdir('entourage')
          yield(ftp)
        end
      end
    end

  end
end
