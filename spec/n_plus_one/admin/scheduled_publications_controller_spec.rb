require 'rails_helper'
include AuthHelper

describe Admin::ScheduledPublicationsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  around { |example| Sidekiq::Testing.disable!(&example) }

  def returned_scheduled_publications_count
    assigns(:grouped_scheduled_publications).values.flatten.size
  end

  describe 'GET index' do
    context 'posts' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            neighborhood = create :neighborhood, name: "Groupe #{SecureRandom.hex(4)}", participants: [create(:public_user)]
            post = create :chat_message, :neighborhood_post, messageable: neighborhood, user: create(:public_user), status: 'scheduled'

            create :scheduled_publication, author: create(:pro_user), publishable: post, neighborhood: neighborhood, scheduled_at: 1.day.from_now
          end
        end

        def perform_request
          get :index, params: { type: :post, mine: :all }
        end

        def returned_items_count
          returned_scheduled_publications_count
        end
      end
    end

    context 'broadcasts' do
      it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : diffusions (ScheduledPublication#publishable recharge le broadcast via find_with_cast à chaque ligne ; target_label et recipients_count requêtent les groupes destinataires par ligne)' do
        def populate(count)
          count.times do
            neighborhoods = create_list :neighborhood, 2, name: "Groupe #{SecureRandom.hex(4)}"
            broadcast = create :neighborhood_message_broadcast, status: 'scheduled', title: "Diffusion #{SecureRandom.hex(4)}", conversation_ids: neighborhoods.map(&:id)

            create :scheduled_publication, author: create(:pro_user), publishable: broadcast, scheduled_at: 2.days.from_now
          end
        end

        def perform_request
          get :index, params: { type: :broadcast, mine: :all }
        end

        def returned_items_count
          returned_scheduled_publications_count
        end
      end
    end
  end
end
