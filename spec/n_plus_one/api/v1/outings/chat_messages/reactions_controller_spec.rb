require 'rails_helper'

describe Api::V1::Outings::ChatMessages::ReactionsController, type: :controller do
  let(:user) { create :pro_user }
  let(:outing) { create :outing, participants: [user] }
  let(:chat_message) { create :chat_message, messageable: outing, user: create(:public_user) }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # chaque réaction créée a son propre type (reaction_id) : elle apparaît comme
      # un élément distinct du résumé (vue chat_message_reactions groupée par reaction_id)
      def populate(count)
        count.times do
          create :user_reaction, instance: chat_message, user: create(:public_user), reaction: create(:reaction, key: "reaction_#{SecureRandom.hex(4)}")
        end
      end

      def perform_request
        get :index, params: { outing_id: outing.to_param, chat_message_id: chat_message.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['reactions'].size
      end
    end
  end
end
