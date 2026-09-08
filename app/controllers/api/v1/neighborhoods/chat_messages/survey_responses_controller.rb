module Api
  module V1
    module Neighborhoods
      module ChatMessages
        class SurveyResponsesController < Api::V1::BaseController
          before_action :set_neighborhood
          before_action :set_chat_message
          before_action :ensure_is_member, only: [:create, :destroy]

          def index
            return render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'No survey' }) unless @chat_message.survey.present?

            render json: { survey_responses: @chat_message.survey_responses.serialize }, status: 200
          end

          def create
            survey = @chat_message.survey_responses.build(user: current_user, responses: params[:responses])

            if survey.save
              render json: survey, status: 201, serializer: ::V1::SurveyResponseSerializer
            else
              render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {
                message: 'Could not create survey', reasons: survey.errors.full_messages
              })
            end
          end

          def destroy
            if survey_id = @chat_message.survey_responses.destroy(user: current_user)
              render json: { survey_id: survey_id }, status: 200
            else
              render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not delete survey' })
            end
          end

          private

          def set_neighborhood
            @neighborhood = Neighborhood.find_by_id_through_context(params[:neighborhood_id], params)

            render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find neighborhood' }) unless @neighborhood.present?
          end

          def set_chat_message
            # we want to force chat_message to belong to Neighborhood
            @chat_message = ChatMessage.where(messageable: @neighborhood).find_by_id_through_context(params[:chat_message_id], params)

            render_error(status: :not_found, code: Api::V1::ErrorCodes::NOT_FOUND, legacy: { message: 'Could not find chat_message' }) unless @chat_message.present?
          end

          def join_request
            @join_request ||= JoinRequest.where(joinable: @neighborhood, user: current_user, status: :accepted).first
          end

          def ensure_is_member
            raise Api::V1::ForbiddenResourceError, 'unauthorized : you are not accepted in this neighborhood' unless join_request
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
