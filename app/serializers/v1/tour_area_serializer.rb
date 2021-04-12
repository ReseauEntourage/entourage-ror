module V1
  class TourAreaSerializer < ActiveModel::Serializer
    attributes :id,
               :departement,
               :area,
               :status,
               :email,
               :created_at,
               :updated_at
  end
end
