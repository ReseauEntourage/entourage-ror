require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessages::ReactionsController, type: :controller do
  let(:user) { create :pro_user }
  let(:neighborhood) { create :neighborhood, participants: [user] }
  let(:chat_message) { create :chat_message, messageable: neighborhood, user: user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # chaque élément retourné = un type de réaction distinct (résumé groupé par reaction_id)
      def populate(count)
        count.times do
          reaction = create :reaction, name: "reaction #{SecureRandom.hex(3)}", key: "key_#{SecureRandom.hex(3)}"
          2.times { create :user_reaction, instance: chat_message, reaction: reaction, user: create(:public_user) }
        end
      end

      def perform_request
        get :index, params: { neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['reactions'].size
      end
    end
  end
end
