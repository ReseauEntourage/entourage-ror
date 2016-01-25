module V0
  class OrganizationSerializer < ActiveModel::Serializer
    attributes :name,
               :description,
               :phone,
               :address,
               :logo_url
  end
end