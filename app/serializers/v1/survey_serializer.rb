module V1
  class SurveySerializer < ActiveModel::Serializer
    attributes :questions,
               :multiple
  end
end
