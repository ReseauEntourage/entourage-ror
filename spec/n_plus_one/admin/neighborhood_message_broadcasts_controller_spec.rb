require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodMessageBroadcastsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # l'onglet "En cours d'envoi" (status: :sending) n'est pas couvert : il liste les
  # diffusions d'après les jobs Sidekiq en attente (ConversationMessageBroadcast.pending_jobs, Redis)

  describe 'GET index' do
    def neighborhood_ids
      [
        create(:neighborhood, user: create(:public_user), participants: [create(:public_user)]).id,
        create(:neighborhood, user: create(:public_user)).id
      ]
    end

    context 'sent' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            create :neighborhood_message_broadcast, status: :sent, sent_recipients_count: 2, conversation_ids: neighborhood_ids
          end
        end

        def perform_request
          get :index, params: { status: :sent }
        end

        def returned_items_count
          assigns(:neighborhood_message_broadcasts).to_a.size
        end
      end
    end

    context 'draft' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            create :neighborhood_message_broadcast, status: :draft, conversation_ids: neighborhood_ids
          end
        end

        def perform_request
          get :index, params: { status: :draft }
        end

        def returned_items_count
          assigns(:neighborhood_message_broadcasts).to_a.size
        end
      end
    end

    context 'draft with a departements selection' do
      it_behaves_like 'an endpoint without N+1 queries' do
        # un département distinct par diffusion : sinon la requête est identique et servie par le cache SQL
        def populate(count)
          count.times do
            @departement = (@departement || 10) + 1
            create(:neighborhood, user: create(:public_user), postal_code: "#{@departement}000")
            broadcast = create :neighborhood_message_broadcast, status: :draft
            broadcast.update_column(:specific_filters, { 'departements' => [@departement.to_s] })
          end
        end

        def perform_request
          get :index, params: { status: :draft }
        end

        def returned_items_count
          assigns(:neighborhood_message_broadcasts).to_a.size
        end
      end
    end

    context 'scheduled' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            broadcast = create :neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now, conversation_ids: neighborhood_ids
            create :scheduled_publication, publishable: broadcast, author: create(:pro_user), scheduled_at: broadcast.scheduled_at
          end
        end

        def perform_request
          get :index, params: { status: :scheduled }
        end

        def returned_items_count
          assigns(:neighborhood_message_broadcasts).to_a.size
        end
      end
    end
  end
end
