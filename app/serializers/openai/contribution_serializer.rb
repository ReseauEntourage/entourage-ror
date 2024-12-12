module Openai
  class ContributionSerializer < ActiveModel::Serializer
    attributes :id, :type, :name, :description

    def type
      :contribution
    end
  end
end
