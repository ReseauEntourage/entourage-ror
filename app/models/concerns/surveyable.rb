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
      survey = @instance.user_survey_responses.find_or_initialize_by(user: user)
      survey.responses = responses
      survey
    end

    def response user_id
      @instance.user_survey_responses.pluck(:user_id, :responses).to_h[user_id]
    end

    def destroy user:
      return unless survey_response = @instance.user_survey_responses.find_by(user: user)

      survey_response.destroy and return survey_response.responses
    end

    def serialize user_serializer: ::V1::Users::BasicSerializer
      formatted_responses = Array.new(@instance.survey.choices.size) { [] }

      # see rspecs for expected output
      @instance.user_survey_responses.includes(:user).each do |survey_response|
        survey_response.responses.each_with_index do |response, index|
          unless ActiveModel::Type::Boolean::FALSE_VALUES.include?(response)
            formatted_responses[index] << user_serializer.new(survey_response.user).as_json
          end
        end
      end

      formatted_responses
    end
  end

  def survey_responses
    SurveyResponseStruct.new(instance: self)
  end

  def survey?
    survey_id.present?
  end
end
