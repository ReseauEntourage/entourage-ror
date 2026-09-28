require 'rails_helper'

describe Api::V1::UserSmalltalksController, type: :controller do
  let(:user) { create :pro_user, goal: :offer_help }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          smalltalk = create :smalltalk, participants: [user, create(:public_user)]
          create :chat_message, messageable: smalltalk, user: user

          # validate: false : la validation de quota (3 smalltalks max par utilisateur)
          # empêcherait de créer assez d'éléments pour le grand jeu de données
          build(:user_smalltalk, user: user, smalltalk: smalltalk, member_status: :accepted).save!(validate: false)
        end
      end

      def perform_request
        # le cache thread-local de BatchLoader (lazy_relationship de SmalltalkSerializer) n'est
        # pas vidé entre deux requêtes en controller spec (pas de middleware) : sans ça, la
        # mesure du petit jeu de données réutiliserait les chargements de la requête de chauffe
        BatchLoader::Executor.clear_current
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['user_smalltalks'].size
      end
    end
  end
end
