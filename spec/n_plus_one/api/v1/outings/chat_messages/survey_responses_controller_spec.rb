require 'rails_helper'

describe Api::V1::Outings::ChatMessages::SurveyResponsesController, type: :controller do
  let(:user) { create :pro_user }
  let(:outing) { create :outing, participants: [user] }
  let(:chat_message) { create :chat_message, messageable: outing, user: user, survey: create(:survey, choices: ['choix 1', 'choix 2', 'choix 3']) }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # chaque réponse est faite par un utilisateur distinct (avatar, profil) et coche plusieurs choix
      def populate(count)
        count.times do
          respondent = create :public_user, avatar_key: "avatar_#{SecureRandom.hex(3)}.jpg", targeting_profile: 'ambassador'
          create :survey_response, chat_message: chat_message, user: respondent, responses: [true, false, true]
        end
      end

      def perform_request
        get :index, params: { outing_id: outing.to_param, chat_message_id: chat_message.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['survey_responses'].flatten.size
      end
    end
  end
end
