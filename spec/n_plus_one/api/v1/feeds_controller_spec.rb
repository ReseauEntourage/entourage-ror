require 'rails_helper'

describe Api::V1::FeedsController, type: :controller do
  let(:user) { create :pro_user }
  let(:latitude) { 48.854367553785 }
  let(:longitude) { 2.27034058909627 }

  # auteur distinct pour chaque élément, rattaché à un partenaire distinct (sinon le cache de requêtes masque les N+1)
  def author
    create :public_user, partner: create(:partner, name: "partner #{SecureRandom.hex(3)}", image_url: "partner_#{SecureRandom.hex(3)}.jpg"),
      avatar_key: "avatar_#{SecureRandom.hex(3)}.jpg", partner_role_title: 'Bénévole'
  end

  def perform_request
    # le cache thread-local de BatchLoader (lazy_relationship d'EntourageSerializer) n'est pas
    # vidé entre deux requêtes en controller spec : on le vide pour mesurer une requête « à froid »
    BatchLoader::Executor.clear_current
    get :index, params: { token: user.token, latitude: latitude, longitude: longitude }
  end

  def returned_items_count
    JSON.parse(response.body)['feeds'].size
  end

  describe 'GET index' do
    context 'actions' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: "N+1 : followings (V1::PartnerSerializer#following fait un Following.exists? par auteur rattaché à un partenaire)" do
        def populate(count)
          count.times do
            action = create :entourage, :joined, user: author, latitude: latitude, longitude: longitude,
              participants: [create(:public_user)]
            # l'utilisateur courant est membre : join_status, number_of_unread_messages
            create :join_request, joinable: action, user: user, status: JoinRequest::ACCEPTED_STATUS
            create :chat_message, messageable: action, user: action.user
          end
        end
      end
    end

    context 'outings' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: "N+1 : image_resize_actions (Entourage#metadata_with_image_paths, 2 par sortie) et followings par partenaire auteur (V1::PartnerSerializer#following)" do
        def populate(count)
          count.times do
            outing = create :outing, :joined, user: author, latitude: latitude, longitude: longitude,
              participants: [create(:public_user)],
              metadata: { landscape_url: "landscape_#{SecureRandom.hex(3)}.jpg", portrait_url: "portrait_#{SecureRandom.hex(3)}.jpg" }
            create :join_request, joinable: outing, user: user, status: JoinRequest::ACCEPTED_STATUS
            create :chat_message, messageable: outing, user: outing.user
          end
        end
      end
    end
  end
end
