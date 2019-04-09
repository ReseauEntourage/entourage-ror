module V1
  class OrganizationSerializer < ActiveModel::Serializer
    attributes :name,
               :description,
               :phone,
               :address,
               :logo_url
  end
end
