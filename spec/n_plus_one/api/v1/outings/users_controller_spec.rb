require 'rails_helper'

describe Api::V1::Outings::UsersController, type: :controller do
  let(:user) { create :public_user }
  let(:outing) { create :outing, :outing_class }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : user_badges, followings et image_resize_actions par membre (UserBadge.all_for_user + PartnerSerializer#following/#image_url)' do
      def populate(count)
        count.times do
          member = create :public_user,
            avatar_key: 'avatar_key',
            partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}", image_url: "partner_#{SecureRandom.hex(4)}.jpg"),
            partner_role_title: 'Bénévole'
          create :user_badge, user: member
          create :join_request, joinable: outing, user: member, status: :accepted, role: :participant
        end
      end

      def perform_request
        get :index, params: { outing_id: outing.to_param, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['users'].size
      end
    end
  end
end
