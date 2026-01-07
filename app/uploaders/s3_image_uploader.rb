# This class must be subclassed.
# See AnnouncementImageUploader for an exemple.
class S3ImageUploader
  CONTENT_TYPES = [
    'image/png',
    'image/jpeg'
  ].freeze

  AUTHORIZED_PARAMS = [
    :object_url,
    :signature_expiration,
    :signature,
    :bucket,
    :key,
    :etag,
    :id,
  ]

  DEFAULT_PATH = "#{Rails.root}/tmp"

  def self.content_types
    CONTENT_TYPES.join(', ')
  end

  def self.default_upload_options
    {
      signature_expiration: 1.minute.from_now,
      cache_control: "private, max-age=#{1.year.to_i}",
    }
  end

  def self.metadata params
    params.slice(*self.metadata_keys)
  end

  def self.form params
    [*self.metadata_keys, :redirect_url].each do |key|
      raise "`#{key}` must be present" if params[key].blank?
    end
    raise "`filetype` must be in #{CONTENT_TYPES}" unless params[:filetype].in?(CONTENT_TYPES)

    extension = EXTENSIONS[params[:filetype]]
    raise if extension.nil?

    key = generate_s3_path(params, extension)
    s3_object = storage.object(key)

    payload = metadata(params).merge(
      object_url: s3_object.public_url,
    )

    redirect_url = append_payload(payload, to: params[:redirect_url])

    post_data = s3_object.presigned_post([
      self.default_upload_options,
      self.upload_options,
      {
        content_type: params[:filetype],
        success_action_redirect: redirect_url
      }
    ].reduce(&:merge))

    return {
      url: post_data.url,
      fields: post_data.fields
    }
  end

  def self.delete_s3_object_with_public_url url
    s3_object_with_public_url(url)&.delete
  end

  private

  EXTENSIONS = {
    'image/png' => 'png',
    'image/jpeg' => 'jpeg',
  }.freeze

  def self.payload params
    extract_payload(params: params, keys: [:object_url, *self.metadata_keys])
  end

  def self.storage
    Storage::Client.avatars
  end

  def self.append_payload payload, to:
    payload = sign_payload(payload)
    url = URI(to)
    url_params = CGI.parse(url.query || '')
    payload.each do |key, value|
      url_params[key.to_s] = value
    end
    url.query = URI.encode_www_form(url_params).presence
    url.to_s
  end

  def self.sign_payload payload, expiration: 1.minute.from_now
    payload[:signature_expiration] = expiration.to_i
    payload.delete(:signature)
    payload[:signature] = SignatureService.sign(signature_key(payload))
    payload
  end

  def self.signature_key params
    URI.encode_www_form(params.sort_by { |key, _| key.to_s })
  end

  def self.extract_payload params:, keys:
    payload = params.slice(*keys, :signature_expiration)
    return nil if payload[:signature_expiration].to_i < Time.now.to_i
    return nil unless SignatureService.validate(signature_key(payload), params[:signature])
    payload.except(:signature_expiration)
  end

  def self.s3_object_with_public_url url
    base_url = storage.object('').public_url
    return nil unless url.starts_with?(base_url)
    key = url[base_url.length..-1]
    storage.object(key)
  end

  def self.ensure_directory_exist
    Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
  end

  def self.resized_image path, ratio
    ensure_directory_exist

    image = MiniMagick::Image.open(path)
    image.resize ratio
    image.write(image.path)
    image.path
  end
end
