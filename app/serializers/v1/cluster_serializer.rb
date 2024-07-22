module V1
  class ClusterSerializer < ActiveModel::Serializer
    attributes :id,
      :type,
      :count,
      :name,
      :category_id,
      :latitude,
      :longitude,

    def type
      return :poi if poi?

      :cluster
    end

    private

    def poi?
      object.count == 1
    end
  end
end
