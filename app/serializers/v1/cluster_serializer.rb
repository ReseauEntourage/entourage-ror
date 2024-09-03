module V1
  class ClusterSerializer < ActiveModel::Serializer
    attributes :type,
      :count,
      :latitude,
      :longitude,
      :id,
      :uuid,
      :name,
      :address,
      :phone,
      :email,
      :category_id

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
