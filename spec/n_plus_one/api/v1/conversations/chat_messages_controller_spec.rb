require 'rails_helper'

describe Api::V1::Conversations::ChatMessagesController, type: :controller do
  let(:user) { create :pro_user }
  let(:conversation) { create :conversation, participants: [user] }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : partners des auteurs (GenericSerializer#user appelle object.user.partner, :user est préchargé mais pas user: :partner) + image_resize_actions (GenericSerializer#image_url)' do
      def populate(count)
        count.times do
          author = create :public_user, partner: create(:partner, name: "Partenaire #{SecureRandom.hex(4)}"), avatar_key: "avatar-#{SecureRandom.hex(4)}", partner_role_title: 'Bénévole'
          create :join_request, joinable: conversation, user: author, status: :accepted

          message = create :chat_message, messageable: conversation, user: author, image_url: "image-#{SecureRandom.hex(4)}.jpg", content: "message #{SecureRandom.hex(4)}"

          translation = Translation.find_or_initialize_by(instance: message)
          translation.update!(fr: { content: message.content }, en: { content: "en #{message.content}" })

          create :user_reaction, instance: message, user: create(:public_user), reaction: create(:reaction)
          create :user_reaction, instance: message, user: user, reaction: create(:reaction)
        end
      end

      def perform_request
        get :index, params: { conversation_id: conversation.to_param, token: user.token, per: 50 }
      end

      def returned_items_count
        JSON.parse(response.body)['chat_messages'].size
      end
    end
  end
end
