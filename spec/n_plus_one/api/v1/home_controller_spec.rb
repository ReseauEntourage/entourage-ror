require 'rails_helper'

describe Api::V1::HomeController, type: :controller do
  let(:user) { create :offer_help_user }

  let(:latitude) { 48.854367553784954 }
  let(:longitude) { 2.270340589096274 }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # chaque "élément" = un événement + une demande + une contribution, chacun avec son
      # propre auteur (partenaire, avatar), ses membres et un message
      def populate(count)
        count.times do
          [
            create(:outing, :joined, user: author, participants: [create(:public_user)]),
            create(:entourage, :joined, user: author, entourage_type: 'ask_for_help', latitude: latitude, longitude: longitude, participants: [user]),
            create(:entourage, :joined, user: author, entourage_type: 'contribution', latitude: latitude, longitude: longitude, participants: [create(:public_user)]),
          ].each do |entourage|
            create :chat_message, messageable: entourage, user: entourage.user
          end
        end
      end

      def author
        create :public_user, avatar_key: 'avatar_key', partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}", image_url: "partner_#{SecureRandom.hex(4)}.jpg")
      end

      def perform_request
        # le cache thread-local de BatchLoader (lazy_relationship d'EntourageSerializer) n'est
        # pas vidé entre deux requêtes en controller spec (pas de middleware) : sans ça, la
        # mesure du petit jeu de données réutiliserait les chargements de la requête de chauffe
        BatchLoader::Executor.clear_current
        get :index, params: { token: user.token, latitude: latitude, longitude: longitude }
      end

      def returned_items_count
        result = JSON.parse(response.body)
        result['outings'].size + result['entourages'].size
      end
    end
  end
end
