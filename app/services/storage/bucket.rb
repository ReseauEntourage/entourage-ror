module Storage
  class Bucket
    attr_reader :bucket_name

    def initialize(bucket_name)
      Aws.config.update({
        region: 'eu-west-1',
        credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
      })
      @bucket = Aws::S3::Bucket.new(bucket_name)
      @bucket_name = bucket_name
    end

    # display public image
    def public_url key:
      bucket.object(key).public_url
    end

    def public_url_with_size key:, size:
      key_sized = key_with_size(key, size)

      bucket.object(key_sized).public_url
    end

    # display private image
    def read_for(key:, extra: {})
      expire = extra[:expire] || 3600

      bucket.object(key).presigned_url(:get, expires_in: expire.to_i)
    end

    # display private image
    def url_for(key:, extra: {})
      expire = extra[:expire] || 3600

      bucket.object(key).presigned_url(:get, expires_in: expire.to_i)
    end

    def url_for_with_size(key:, size:, extra: {})
      expire = extra[:expire] || 3600
      key_sized = key_with_size(key, size)

      bucket.object(key_sized).presigned_url(:get, expires_in: expire.to_i)
    end

    def upload(file:, key:, extra: {})
      object(key).upload_file(file, content_type: extra[:content_type])
    end

    def destroy(key:)
      object(key).delete
    end

    def object(key)
      bucket.object(key)
    end

    private
    attr_reader :bucket

    def key_with_size(key, size)
      ImageResizeAction.find_path_for(bucket: @bucket_name, path: key, size: size)
    end
  end
end
