class UploadPresenter < ApplicationPresenter
  require 'json'
  def json
    if presigned_post
      presigned_post.fields
    end
  end

  def url
    if presigned_post
      presigned_post.url
    end
  end

  def host
    if presigned_post
      URI.parse(url).host
    end
  end

  private

  def presigned_post
    if bucket
      bucket.presigned_post(key: "#{SecureRandom.uuid}_${filename}", success_action_status: '201', acl: 'private', content_type_starts_with: 'image/')
    end
  end

  def bucket
    Aws.config.update({
                          region: 'eu-west-1',
                          credentials: Aws::Credentials.new(ENV['ENTOURAGE_AWS_ACCESS_KEY_ID'], ENV['ENTOURAGE_AWS_SECRET_ACCESS_KEY']),
                      })
    Aws::S3::Resource.new.bucket(ENV['ENTOURAGE_UPLOAD_BUCKET'], )
  end
end
