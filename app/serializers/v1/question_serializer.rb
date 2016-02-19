module V1
  class QuestionSerializer < ActiveModel::Serializer
    attributes :id,
               :title,
               :answer_type
  end
end