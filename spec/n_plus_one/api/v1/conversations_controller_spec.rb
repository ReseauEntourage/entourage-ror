require 'rails_helper'

describe Api::V1::ConversationsController, type: :controller do
  let(:user) { create :public_user }

  def partner_user(**attributes)
    create :public_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}"), **attributes
  end

  describe 'GET index' do
    context 'private conversations' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            participant = partner_user(avatar_key: 'avatar', targeting_profile: :ambassador)
            conversation = create :conversation, user: user, participants: [user, participant]

            create :chat_message, messageable: conversation, user: participant
            create :chat_message, messageable: conversation, user: user
          end
        end

        def perform_request
          # le cache thread-local de BatchLoader (lazy_relationship) n'est pas vidé entre deux
          # requêtes de controller spec : sans cela, la mesure "petit jeu" réutiliserait les
          # relations chargées pendant la chauffe
          BatchLoader::Executor.clear_current
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['conversations'].size
        end
      end
    end

    context 'outings' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            creator = partner_user(avatar_key: 'avatar')
            outing = create :outing, :outing_class,
              user: creator,
              participants: [user, partner_user],
              metadata: { portrait_url: "portrait-#{SecureRandom.hex(4)}.jpg" }

            create :chat_message, messageable: outing, user: creator
          end
        end

        def perform_request
          # le cache thread-local de BatchLoader (lazy_relationship) n'est pas vidé entre deux
          # requêtes de controller spec : sans cela, la mesure "petit jeu" réutiliserait les
          # relations chargées pendant la chauffe
          BatchLoader::Executor.clear_current
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['conversations'].size
        end
      end
    end
  end
end
