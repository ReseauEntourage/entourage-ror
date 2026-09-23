require 'rails_helper'

describe Api::V1::InappNotificationsController, type: :controller do
  let(:user) { create :pro_user }

  describe 'GET index' do
    context 'chat messages created (sender + post)' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            sender = create :public_user, avatar_key: 'avatar'
            neighborhood = create :neighborhood, user: create(:public_user), participants: [user, sender]
            post = create :chat_message, messageable: neighborhood, user: sender

            create :inapp_notification,
              user: user,
              sender: sender,
              instance: :neighborhood_post,
              instance_id: post.id,
              post: post,
              context: :chat_message_on_create
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['inapp_notifications'].size
        end
      end
    end

    context 'outings updated (record lookup)' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: 'N+1 : entourages (InappNotification#record fait un find_by_id par notification, appelé par le serializer pour image_url)' do
        def populate(count)
          count.times do
            sender = create :public_user, avatar_key: 'avatar'
            outing = create :outing, :outing_class, user: sender, participants: [user],
              metadata: { landscape_url: "landscape-#{SecureRandom.hex(4)}.jpg" }

            create :inapp_notification,
              user: user,
              sender: sender,
              instance: :outing,
              instance_id: outing.id,
              context: :outing_on_update
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['inapp_notifications'].size
        end
      end
    end
  end
end
