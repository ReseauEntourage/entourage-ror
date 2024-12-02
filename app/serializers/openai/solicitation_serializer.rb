module Openai
  class SolicitationSerializer < ActiveModel::Serializer
    attributes :id, :name, :description
  end
end
