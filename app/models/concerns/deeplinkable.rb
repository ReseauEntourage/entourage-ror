module Deeplinkable
  extend ActiveSupport::Concern


  class_methods do
    def find_by_id_through_context id, params
      return find(id) unless params.has_key?(:deeplink)
      return find_by_uuid_v2(id) if attribute_names.include?("uuid_v2")

      find(id) # fallback whenever it is a deeplink but table does not define uuid_v2
    end
  end
end
