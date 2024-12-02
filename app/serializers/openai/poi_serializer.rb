module Openai
  class PoiSerializer < ActiveModel::Serializer
    attributes :id, :name
  end
end
