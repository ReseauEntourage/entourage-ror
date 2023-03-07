module Deeplinkable
  extend ActiveSupport::Concern

  included do
    before_create :set_uuid
  end

  class_methods do
    def find_by_id_through_context id, params
      return find(id) unless params.has_key?(:deeplink)
      return find_by_uuid_v2(id) if attribute_names.include?("uuid_v2")

      # fallback whenever it is a deeplink but table does not define uuid_v2
      find(id)
    end

    def generate_uuid_v2
      'e' + SecureRandom.urlsafe_base64(8)
    end
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
    if attribute_names.include?("uuid")
      self.uuid = nil if force
      self.uuid ||= SecureRandom.uuid
    end

    if attribute_names.include?("uuid_v2")
      self.uuid_v2 = nil if force
      self.uuid_v2 ||= self.class.generate_uuid_v2
    end

    true
  end
end
