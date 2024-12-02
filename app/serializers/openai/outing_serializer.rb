module Openai
  class OutingSerializer < ActiveModel::Serializer
    attributes :id, :name, :description
  end
end
