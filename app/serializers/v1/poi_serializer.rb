module V1
  class PoiSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid,
               :source,
               :source_url,
               :name,
               :description,
               :longitude,
               :latitude,
               :adress,
               :address,
               :phone,
               :website,
               :email,
               :audience,
               :hours,
               :languages,
               :validated,
               :category_id,
               :partner_id,
               :category_ids

    has_one :category

    def filter(keys)
      case version
      when :v1_list
        keys & [:id, :name, :description, :longitude, :latitude, :adress,
                :phone, :website, :email, :audience, :validated, :category_id,
                :partner_id, :category]
      when :v2_list
        keys & [:uuid, :name, :latitude, :longitude, :address, :phone, :category_id, :partner_id]
      when :v2
        keys - [:id, :adress, :validated, :category, :category_id]
      else
        keys
      end
    end

    def category_id
      case version
      when :v1_list
        {
          40 => 4,
          41 => 4,
          42 => 4,
          43 => 4,
          61 => 6,
          62 => 6
        }[object.category_id] || object.category_id
      else
        category_ids.many? ? 0 : category_ids.first
      end
    end

    def category_ids
      @category_ids ||= CategoryPoi.where(poi_id: object.id).pluck(:category_id)
    end

    private

    def version
      scope&.[](:version)
    end
  end
end
