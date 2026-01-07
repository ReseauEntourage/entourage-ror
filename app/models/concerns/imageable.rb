module Imageable
  extend ActiveSupport::Concern

  CONTENT_TYPES = %w(image/jpeg)

  class_methods do
    def bucket
      Storage::Client.images
    end

    def bucket_name
      bucket.bucket_name
    end

    def image_url_for url
      bucket.public_url(key: url)
    end

    def presigned_url key, content_type
      bucket.object(path key).presigned_url(
        :put,
        expires_in: 1.minute.to_i,
        acl: 'public-read',
        content_type: content_type,
        cache_control: "max-age=#{365.days}"
      )
    end

    def url_for key
      bucket.url_for(key: path(key), extra: { expire: 1.day })
    end

    def url_for_with_size key, size
      bucket.public_url_with_size(key: path(key), size: size)
    end

    def path key
      "#{bucket_prefix}/#{key}"
    end

    def bucket_prefix
      table_name
    end
  end
end
