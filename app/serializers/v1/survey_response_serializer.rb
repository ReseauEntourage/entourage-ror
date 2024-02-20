module V1
  class SurveyResponseSerializer < ActiveModel::Serializer
    attributes :responses

    has_one :user, serializer: ::V1::Users::BasicSerializer
  end
end
