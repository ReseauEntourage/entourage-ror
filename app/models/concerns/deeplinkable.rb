module Deeplinkable
  extend ActiveSupport::Concern

  included do
    before_create :set_uuid
  end

  class_methods do
    def find_by_id_through_context identifier, params
      return find_by_id_or_uuid(identifier) unless params.has_key?(:deeplink)
      return find_by_uuid_v2(identifier) if attribute_names.include?('uuid_v2')

      # fallback whenever it is a deeplink but table does not define uuid_v2
      find(identifier)
    end

    def find_by_id_or_uuid identifier
      return find_by_id(identifier) unless identifier.is_a?(String)
      return find_by_uuid_v2(identifier) if identifier.start_with?('1_hash_') && attribute_names.include?('uuid_v2')
      return find_by_uuid(identifier) if identifier.length == 36 && attribute_names.include?('uuid')
      return find_by_uuid_v2(identifier) if identifier.length == 12 && attribute_names.include?('uuid_v2')

      find_by_id(identifier)
    end

    def find_by_id_or_uuid! identifier
      raise ActiveRecord::RecordNotFound unless record = find_by_id_or_uuid(identifier)

      record
    end

    def generate_uuid_v2
      'e' + SecureRandom.urlsafe_base64(8)
    end
  end

  def share_url
    return unless uuid_v2

    "#{ENV['MOBILE_HOST']}/app/#{self.class.name.underscore.pluralize}/#{uuid_v2}"
  end

  private

  # If the record creation fails because of an non-unique uuid_v2,
  # generates a new uuid_v2 and retries (at most 3 times in total)
  def _create_record
    tries ||= 1
    transaction(requires_new: true) { super }
  rescue ActiveRecord::RecordNotUnique => e
    raise e unless /uuid_v2/ === e.cause.error
    raise e if tries == 3

    set_uuid(true)

    tries += 1

    retry
  end

  def set_uuid force = false
    if attribute_names.include?('uuid')
      self.uuid = nil if force
      self.uuid ||= SecureRandom.uuid
    end

    if attribute_names.include?('uuid_v2')
      self.uuid_v2 = nil if force
      self.uuid_v2 ||= self.class.generate_uuid_v2
    end

    true
  end
end
