module Surveyable
  extend ActiveSupport::Concern

  included do
    belongs_to :survey, optional: true, dependent: :destroy
    accepts_nested_attributes_for :survey

    has_many :survey_responses
  end
end
