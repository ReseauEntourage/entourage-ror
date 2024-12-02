module Openai
  class ContributionSerializer < ActiveModel::Serializer
    attributes :id, :name, :description
  end
end
