module Openai
  class ResourceSerializer < ActiveModel::Serializer
    attributes :id, :name, :is_video, :description

    def description
      object.text_description_only
    end
  end
end
