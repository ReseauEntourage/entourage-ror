require 'rails_helper'

describe Api::V1::Entourages::UsersController, type: :controller do
  let(:user) { create :public_user }
  let(:entourage) { create :entourage, :joined, user: user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          member = create :public_user,
            partner: create(:partner, name: "Partenaire #{SecureRandom.hex(4)}"),
            avatar_key: "avatar-#{SecureRandom.hex(4)}",
            partner_role_title: 'Bénévole',
            birthdate: '1990-01-01',
            targeting_profile: 'partner'

          create :user_badge, user: member, badge_tag: 'bienvenue'
          create :join_request, joinable: entourage, user: member, status: :accepted, message: "bonjour #{SecureRandom.hex(4)}"
        end
      end

      def perform_request
        get :index, params: { entourage_id: entourage.to_param, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['users'].size
      end
    end
  end
end
