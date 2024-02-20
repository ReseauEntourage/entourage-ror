module V1
  class SurveySerializer < ActiveModel::Serializer
    attributes :questions,
               :multiple,
               :summary
  end
end
