module V0
  class CategorySerializer < ActiveModel::Serializer
    attributes :id,
               :name
  end
end