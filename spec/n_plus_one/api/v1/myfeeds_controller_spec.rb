require 'rails_helper'

# Utilisateur "public" : MyFeedFinder passe par user.community.entourages (entourages_only) ;
# utilisateur "pro" : par user.community.feeds (vue SQL `feeds`).
describe Api::V1::MyfeedsController, type: :controller do
  let(:user) { create :public_user }

  describe 'GET index' do
    # partenaire distinct (nom unique, logo distinct pour ne pas être masqué par le cache SQL)
    def create_partner_author
      key = SecureRandom.hex(4)
      create(:public_user, avatar_key: 'avatar.jpg', partner: create(:partner, name: "Partner #{key}", image_url: "logo-#{key}.jpg"))
    end

    def add_messages(entourage)
      create :chat_message, messageable: entourage, user: create(:public_user, avatar_key: 'avatar.jpg'), content: 'last message'
      create :join_request, joinable: entourage, user: create(:public_user), status: JoinRequest::PENDING_STATUS if entourage.action?
    end

    context 'actions' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: 'N+1 : author.partner (PartnerSerializer : Following.exists? + ImageResizeAction du logo, par partenaire)' do
        def populate(count)
          count.times do
            author = create_partner_author
            entourage = create :entourage, :joined, user: author, participants: [user, create(:public_user)]
            add_messages(entourage)
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['feeds'].size
        end
      end
    end

    context 'outings' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: 'N+1 : images des outings (metadata_with_image_paths -> ImageResizeAction.find_path_for, sans preload_images)' do
        def populate(count)
          count.times do
            key = SecureRandom.hex(4)
            outing = create :outing, :outing_class,
              user: create(:public_user, avatar_key: 'avatar.jpg'),
              participants: [user, create(:public_user)],
              metadata: { landscape_url: "landscape-#{key}.jpg", portrait_url: "portrait-#{key}.jpg" }
            add_messages(outing)
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['feeds'].size
        end
      end
    end

    context 'conversations' do
      it_behaves_like 'an endpoint without N+1 queries',
        pending: 'N+1 : accepted_members, member_ids et user_blocked_users par conversation (EntourageSerializer#initialize + Blockers)' do
        def populate(count)
          count.times do
            other = create(:public_user, avatar_key: 'avatar.jpg')
            conversation = create :conversation, user: other, participants: [user, other]
            add_messages(conversation)
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['feeds'].size
        end
      end
    end

    context 'actions, pro user (feeds view)' do
      let(:user) { create :pro_user }

      it_behaves_like 'an endpoint without N+1 queries',
        pending: 'N+1 : author.partner (PartnerSerializer : Following.exists? + ImageResizeAction du logo, par partenaire)' do
        def populate(count)
          count.times do
            author = create_partner_author
            entourage = create :entourage, :joined, user: author, participants: [user, create(:public_user)]
            add_messages(entourage)
          end
        end

        def perform_request
          get :index, params: { token: user.token }
        end

        def returned_items_count
          JSON.parse(response.body)['feeds'].size
        end
      end
    end
  end
end
