require 'rails_helper'

describe Api::V1::Outings::ChatMessagesController, type: :controller do
  let(:user) { create :public_user }
  let(:outing) { create :outing }
  let!(:join_request) { create :join_request, joinable: outing, user: user, status: :accepted }
  let(:reaction) { create :reaction }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : partners (includes(:user) sans :partner) + image_resize_actions (GenericSerializer#image_url -> ChatMessage#image_url_with_size -> ImageResizeAction.find_path_for)' do
      def populate(count)
        count.times do
          hex = SecureRandom.hex(4)
          author = create :partner_user,
            partner: create(:partner, name: "Partner #{hex}", image_url: "partner_#{hex}.jpg"),
            avatar_key: "avatar_#{hex}"
          create :join_request, joinable: outing, user: author, status: :accepted

          message = create :chat_message, messageable: outing, user: author,
            content: "message #{hex}", image_url: "chat_#{hex}.jpg", survey: create(:survey)

          # commentaire, réactions, réponse au sondage et traduction propres à chaque post
          create :chat_message, messageable: outing, user: create(:public_user), parent: message
          create :user_reaction, instance: message, reaction: reaction, user: author
          create :user_reaction, instance: message, reaction: reaction, user: user
          create :survey_response, chat_message: message, user: user, responses: [true, false]
          message.translation || create(:translation, instance: message)
        end
      end

      def perform_request
        get :index, params: { outing_id: outing.to_param, token: user.token, per: 50 }
      end

      def returned_items_count
        JSON.parse(response.body)['chat_messages'].size
      end
    end
  end
end
