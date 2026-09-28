require 'rails_helper'

describe Api::V1::Smalltalks::ChatMessages::SurveyResponsesController, type: :controller do
  let(:user) { create :pro_user }
  let(:smalltalk) { create :smalltalk, participants: [user] }
  let(:chat_message) { create :chat_message, messageable: smalltalk, user: user, survey: create(:survey) }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          respondent = create :public_user, avatar_key: 'avatar', targeting_profile: :ambassador
          create :join_request, joinable: smalltalk, user: respondent, status: JoinRequest::ACCEPTED_STATUS
          create :survey_response, chat_message: chat_message, user: respondent, responses: [true, true]
        end
      end

      def perform_request
        get :index, params: { smalltalk_id: smalltalk.to_param, chat_message_id: chat_message.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['survey_responses'].flatten.map { |respondent| respondent['id'] }.uniq.size
      end
    end
  end
end
