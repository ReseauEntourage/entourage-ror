module Storage
  class Client
    def self.images
      Storage::Bucket.new(ENV['ENTOURAGE_IMAGES_BUCKET'])
    end

    def self.avatars
      @avatars ||= Storage::Bucket.new(ENV['ENTOURAGE_AVATARS_BUCKET'])
    end

    def self.csv
      Storage::Bucket.new('entourage-csv')
    end
  end
end
