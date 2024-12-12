module Openai
  class ResourceSerializer < ActiveModel::Serializer
    attributes :id, :type, :name, :is_video, :description

    def type
      :resource
    end

    def description
      object.text_description_only
    end
  end
end
