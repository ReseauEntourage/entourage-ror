require 'rails_helper'

describe Api::V1::Smalltalks::ChatMessages::ReactionsController, type: :controller do
  let(:user) { create :pro_user }
  let(:smalltalk) { create :smalltalk, participants: [user] }
  let(:chat_message) { create :chat_message, messageable: smalltalk, user: user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # chaque élément retourné est un type de réaction (résumé) : on crée donc une
      # réaction distincte par élément, avec plusieurs utilisateurs qui l'ont choisie
      def populate(count)
        count.times do
          reaction = create :reaction, key: "key_#{SecureRandom.hex(4)}", name: 'Reaction'
          2.times { create :user_reaction, instance: chat_message, reaction: reaction, user: create(:public_user) }
        end
      end

      def perform_request
        get :index, params: { smalltalk_id: smalltalk.to_param, chat_message_id: chat_message.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['reactions'].size
      end
    end
  end
end
