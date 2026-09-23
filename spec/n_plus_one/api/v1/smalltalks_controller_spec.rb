require 'rails_helper'

describe Api::V1::SmalltalksController, type: :controller do
  let(:user) { create :pro_user, goal: :offer_help }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : users (accepted_members.limit(5) dans V1::SmalltalkSerializer#members) et meetings (Smalltalk#meeting_url, meeting non préchargé)' do
      def populate(count)
        count.times do
          other = create :public_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}")
          smalltalk = create :smalltalk, participants: [user, other]

          create :chat_message, messageable: smalltalk, user: other, content: "Hello #{smalltalk.id}"
          create :chat_message, messageable: smalltalk, user: user, content: "Hi #{smalltalk.id}"
        end
      end

      # V1::SmalltalkSerializer utilise ams_lazy_relationships (batch-loader) : sans
      # BatchLoader::Middleware, les valeurs chargées restent en cache dans le thread d'une
      # requête à l'autre, et la mesure "petit jeu" ne verrait pas les requêtes batchées.
      def perform_request
        BatchLoader::Executor.clear_current
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['smalltalks'].size
      end
    end
  end
end
