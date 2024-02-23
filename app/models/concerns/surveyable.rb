module Surveyable
  extend ActiveSupport::Concern

  included do
    belongs_to :survey, optional: true, dependent: :destroy
    accepts_nested_attributes_for :survey

    has_many :user_survey_responses, class_name: 'SurveyResponse'
  end

  SurveyResponseStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def build user:, responses:
      @instance.user_survey_responses.build(user: user, responses: responses)
    end

    def response user_id
      @instance.user_survey_responses.where(user_id: user_id).pluck(:responses).first
    end

    def destroy user:
      return unless survey_response = @instance.user_survey_responses.find_by(user: user)

      survey_response.destroy and return survey_response.responses
    end
  end

  def survey_responses
    SurveyResponseStruct.new(instance: self)
  end

  def survey?
    survey_id.present?
  end
end
