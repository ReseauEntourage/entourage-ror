module V1
  class SurveySerializer < ActiveModel::Serializer
    attributes :choices,
               :multiple,
               :summary
  end
end
