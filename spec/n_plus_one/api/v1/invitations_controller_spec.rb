require 'rails_helper'

describe Api::V1::InvitationsController, type: :controller do
  let(:user) { create :pro_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : users (inviter), partners (inviter.partner) et join_requests (statut) chargés par invitation (V1::EntourageInvitationSerializer#inviter / #status)' do
      def populate(count)
        count.times do
          @invitation_index = (@invitation_index || 0) + 1
          inviter = create :partner_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}")
          invitable = create :entourage, user: create(:public_user), title: "Action #{@invitation_index}"

          create :entourage_invitation,
            invitee: user,
            inviter: inviter,
            invitable: invitable,
            # alterne les deux modes pour couvrir les deux branches de #inviter
            invitation_mode: @invitation_index.even? ? 'partner_following' : 'SMS',
            phone_number: "+336#{format('%08d', @invitation_index)}"

          create :join_request, user: user, joinable: invitable, status: JoinRequest::PENDING_STATUS
        end
      end

      def perform_request
        get :index, params: { token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['invitations'].size
      end
    end
  end
end
