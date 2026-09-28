require 'rails_helper'

describe Api::V1::Users::EntouragesController, type: :controller do
  let(:user) { create :pro_user }

  # auteur distinct pour chaque élément, rattaché à un partenaire distinct (sinon le cache de requêtes masque les N+1)
  def author
    create :public_user, partner: create(:partner, name: "partner #{SecureRandom.hex(3)}", image_url: "partner_#{SecureRandom.hex(3)}.jpg"),
      avatar_key: "avatar_#{SecureRandom.hex(3)}.jpg", partner_role_title: 'Bénévole'
  end

  def join!(joinable)
    create :join_request, joinable: joinable, user: user, status: JoinRequest::ACCEPTED_STATUS
  end

  def perform_request
    # le cache thread-local de BatchLoader (lazy_relationship d'EntourageSerializer) n'est pas
    # vidé entre deux requêtes en controller spec : sans ça, la mesure du petit jeu de données
    # réutiliserait les chargements (join_requests, chat_messages_count) de la requête de chauffe
    BatchLoader::Executor.clear_current
    get :index, params: { user_id: user.id, token: user.token }
  end

  def returned_items_count
    JSON.parse(response.body)['entourages'].size
  end

  describe 'GET index' do
    context 'actions ouvertes' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            action = create :entourage, :joined, user: author, participants: [create(:public_user)]
            join!(action)
            create :chat_message, messageable: action, user: action.user
          end
        end
      end
    end

    context 'actions clôturées (outcome)' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            action = create :entourage, :joined, :outcome_oui, user: author, status: :closed, participants: [create(:public_user)]
            join!(action)
          end
        end
      end
    end

    context 'outings' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            outing = create :outing, :joined, user: author, participants: [create(:public_user)],
              metadata: { landscape_url: "landscape_#{SecureRandom.hex(3)}.jpg", portrait_url: "portrait_#{SecureRandom.hex(3)}.jpg" }
            join!(outing)
            create :chat_message, messageable: outing, user: outing.user
          end
        end
      end
    end

    context 'conversations' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            other = author
            conversation = create :conversation, user: user, participants: [user, other]
            create :chat_message, messageable: conversation, user: other
          end
        end
      end
    end
  end
end
