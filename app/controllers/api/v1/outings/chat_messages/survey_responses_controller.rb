module Api
  module V1
    module Outings
      module ChatMessages
        class UnauthorizedSurveyResponse < StandardError; end

        class SurveyResponsesController < Api::V1::BaseController
          before_action :set_outing
          before_action :set_chat_message
          before_action :ensure_is_member, only: [:create, :destroy]

          rescue_from Api::V1::Outings::ChatMessages::UnauthorizedSurveyResponse do |exception|
            render json: { message: 'unauthorized : you are not accepted in this outing' }, status: :unauthorized
          end

          def index
            render json: @chat_message.user_survey_responses.includes(:user).page(page).per(per),
              root: :survey_responses,
              each_serializer: ::V1::SurveyResponseSerializer
          end

          def create
            survey = @chat_message.survey_responses.build(user: current_user, responses: params[:responses])

            if survey.save
              render json: survey, status: 201, serializer: ::V1::SurveyResponseSerializer
            else
              render json: {
                message: "Could not create or update survey", reasons: survey.errors.full_messages
              }, status: 400
            end
          end

          def destroy
            if survey_id = @chat_message.survey_responses.destroy(user: current_user)
              render json: { survey_id: survey_id }, status: 200
            else
              render json: { message: "Could not delete survey" }, status: 400
            end
          end

          private

          def set_outing
            @outing = Outing.find_by_id_through_context(params[:outing_id], params)

            render json: { message: 'Could not find outing' }, status: 400 unless @outing.present?
          end

          def set_chat_message
            # we want to force chat_message to belong to Outing
            @chat_message = ChatMessage.where(messageable: @outing).find_by_id_through_context(params[:chat_message_id], params)

            render json: { message: 'Could not find chat_message' }, status: 400 unless @chat_message.present?
          end

          def join_request
            @join_request ||= JoinRequest.where(joinable: @outing, user: current_user, status: :accepted).first
          end

          def ensure_is_member
            raise Api::V1::Outings::ChatMessages::UnauthorizedSurveyResponse unless join_request
          end

          def page
            params[:page] || 1
          end

          def per
            params[:per] || 25
          end
        end
      end
    end
  end
end
