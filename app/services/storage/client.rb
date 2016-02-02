module Storage
  class Client
    def self.images
      Storage::Bucket.new(ENV["ENTOURAGE_IMAGES_BUCKET"])
    end

    def self.avatars
      Storage::Bucket.new(ENV["ENTOURAGE_AVATARS_BUCKET"])
    end
  end
end