module Openai
  class SolicitationSerializer < ActiveModel::Serializer
    attributes :id, :type, :name, :description

    def type
      :solicitation
    end
  end
end
