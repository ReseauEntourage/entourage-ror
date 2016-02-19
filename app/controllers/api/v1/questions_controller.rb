module Api
  module V1
    class QuestionsController < Api::V1::BaseController
      def index
        questions = @current_user.organization.questions
        render json: questions, each_serializer: ::V1::QuestionSerializer
      end
    end
  end
end