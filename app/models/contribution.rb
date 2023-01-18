class Contribution < Entourage
  include Actionable
  include Sectionable
  include Recommandable

  CONTENT_TYPES = %w(image/jpeg)
  BUCKET_PREFIX = "contributions"

  default_scope {
    where(group_type: :action, entourage_type: :contribution)
    .where(pin: false)
    .order(created_at: :desc)
  }

  def image_path
    return unless image_url

    Contribution.url_for(image_url)
  end

  class << self
    def bucket
      Storage::Client.images
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

    def path key
      "#{BUCKET_PREFIX}/#{key}"
    end
  end
end
