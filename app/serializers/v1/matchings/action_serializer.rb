module V1
  module Matchings
    class ActionSerializer < ActiveModel::Serializer
      include V1::Entourages::Location

      attributes :uuid_v2,
        :status,
        :title,
        :description,
        :created_at,
        :distance

      has_one :location
    end
  end
end
