module Openai
  class PoiSerializer < ActiveModel::Serializer
    attributes :id, :type, :name

    def type
      :poi
    end
  end
end
