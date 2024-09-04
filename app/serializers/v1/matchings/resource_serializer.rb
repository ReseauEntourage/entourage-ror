module V1
  module Matchings
    class ResourceSerializer < ActiveModel::Serializer
      attributes :uuid_v2,
        :name,
        :is_video,
        :category
    end
  end
end
