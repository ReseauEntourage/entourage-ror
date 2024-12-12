module Openai
  class OutingSerializer < ActiveModel::Serializer
    attributes :id, :type, :name, :description

    def type
      :outing
    end
  end
end
