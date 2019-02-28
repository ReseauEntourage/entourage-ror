module V0
  class MapSerializer < ActiveModel::Serializer
    attributes :categories
    has_many :pois

    def categories
      [1, 2]
    end
  end
end
