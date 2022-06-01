module Storage
  class Bucket
    def initialize(bucket_name)
      Aws.config.update({
        region: 'eu-west-1',
        credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
      })
      @bucket = Aws::S3::Bucket.new(bucket_name)
      @default_folder = ENV["ENTOURAGE_AVATARS_FOLDER"]
    end

    def public_url key:
      object(key).public_url
    end

    def read_for(key:, extra: {})
      expire = extra[:expire] || 3600
      bucket.object(key).presigned_url(:get, expires_in: expire.to_i)
    end

    def url_for(key:, extra: {})
      expire = extra[:expire] || 3600
      object(key).presigned_url(:get, expires_in: expire.to_i)
    end

    def upload(file:, key:, extra: {})
      object(key).upload_file(file, content_type: extra[:content_type])
    end

    def destroy(key:)
      object(key).delete
    end

    def object(key)
      bucket.object(key_with_folder(key))
    end

    private
    attr_reader :bucket

    def key_with_folder(key)
      return key unless @default_folder.present?
      return key if key.start_with? @default_folder

      "#{@default_folder}/#{key}"
    end
  end
end
