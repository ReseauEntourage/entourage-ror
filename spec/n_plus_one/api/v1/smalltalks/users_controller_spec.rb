require 'rails_helper'

describe Api::V1::Smalltalks::UsersController, type: :controller do
  let(:user) { create :public_user }
  let!(:smalltalk) { create :smalltalk, participants: [user] }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries',
      pending: 'N+1 : user_badges (UserBadge.all_for_user), 1 requête par membre' do
      # chaque membre a son propre partenaire, son badge et son avatar
      def populate(count)
        count.times do
          partner = create :partner, name: "Asso #{SecureRandom.hex(4)}", image_url: "#{SecureRandom.hex(4)}.jpg"
          member = create :public_user, partner: partner, partner_role_title: 'bénévole', avatar_key: 'avatar'
          create :user_badge, user: member, badge_tag: 'bienvenue'

          create :join_request, joinable: smalltalk, user: member, status: :accepted, role: :member
        end
      end

      def perform_request
        get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['users'].size
      end
    end
  end
end
