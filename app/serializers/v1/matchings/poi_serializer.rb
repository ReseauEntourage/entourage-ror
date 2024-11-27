module V1
  module Matchings
    class PoiSerializer < ActiveModel::Serializer
      include V1::Entourages::Location

      attributes :uuid,
        :name,
        :description,
        :address,
        :audience,
        :hours,
        :languages

      has_one :location
    end
  end
end
