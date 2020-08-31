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
               :partner_id

    has_one :category
  end
end
