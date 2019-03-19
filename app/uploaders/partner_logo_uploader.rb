module PartnerLogoUploader
  CONTENT_TYPES = [
    'image/png',
    'image/jpeg'
  ].freeze

  def self.content_types
    CONTENT_TYPES.join(', ')
  end

  def self.form params
    raise if params[:partner_id].blank?
    raise if params[:redirect_url].blank?
    raise unless params[:filetype].in?(CONTENT_TYPES)

    extension = EXTENSIONS[params[:filetype]]
    raise if extension.nil?

    key = "#{SecureRandom.uuid}.#{extension}"
    s3_object = storage.object("partners/logo/#{key}")

    payload = {
      object_url: s3_object.public_url,
      partner_id: params[:partner_id]
    }

    redirect_url = append_payload(payload, to: params[:redirect_url])

    post_data = s3_object.presigned_post(
      signature_expiration: 1.minute.from_now,
      acl: 'public-read',
      cache_control: "private, max-age=#{1.year.to_i}",
      content_type: params[:filetype],
      success_action_redirect: redirect_url
    )

    return {
      url: post_data.url,
      fields: post_data.fields
    }
  end

  def self.handle_success params
    payload = PartnerLogoUploader.payload(params)
    raise if payload.nil?

    partner = Partner.find(payload[:partner_id])
    previous_logo = partner.large_logo_url
    partner.update_column(:large_logo_url, payload[:object_url])

    AsyncService.new(self).delete_s3_object_with_public_url(previous_logo)

    partner
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
    extract_payload(params: params, keys: [:object_url, :partner_id])
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
    base_url = storage.object(nil).public_url
    return nil unless url.starts_with?(base_url)
    key = url[base_url.length..-1]
    storage.object(key)
  end
end
