module V1
  class RecommandationSerializer < ActiveModel::Serializer
    attributes :name,
      :type,
      :action,
      :image_url,
      :params

    def type
      object.instance
    end

    def params
      {
        id: nil,
        uuid: nil,
        url: nil
      }.map do |key, value|
        [key, key == object.instance_key ? object.instance_id : value]
      end.to_h
    end
  end
end
