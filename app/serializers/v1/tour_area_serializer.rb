module V1
  class TourAreaSerializer < ActiveModel::Serializer
    attributes :id,
               :departement,
               :area,
               :status
  end
end
