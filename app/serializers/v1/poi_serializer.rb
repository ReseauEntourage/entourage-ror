module V1
  class PoiSerializer < ActiveModel::Serializer
    attributes :id,
               :name,
               :description,
               :longitude,
               :latitude,
               :adress,
               :phone,
               :website,
               :email,
               :audience,
               :validated,
               :category_id,
               :partner_id,
               :category_ids

    has_one :category

    def filter(keys)
      case version
      when :v1_list
        keys - [:category_ids]
      when :v2_list
        keys & [:id, :name, :latitude, :longitude, :adress, :phone, :category_id, :partner_id]
      when :v2
        keys - [:validated, :category]
      else
        keys
      end
    end

    def category_id
      if version == :v1
        {
          40 => 4,
          41 => 4,
          42 => 4,
          43 => 4,
          61 => 6,
          62 => 6
        }[object.category_id] || object.category_id
      else
        object.category_id
      end
    end

    def category_ids
      [category_id]
    end

    private

    def version
      scope&.[](:version)
    end
  end
end
