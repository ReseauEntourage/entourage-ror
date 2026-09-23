require 'rails_helper'

describe Api::V1::Users::OutingsController, type: :controller do
  let(:user) { create :pro_user }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : partners (auteur), image_resize_actions (landscape_url), neighborhoods (pluck) et member_ids par événement (includes incomplet, V1::OutingSerializer)' do
      def populate(count)
        count.times do
          author = create :public_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}")

          create :outing, :with_recurrence,
            user: author,
            participants: [user, create(:public_user)],
            interest_list: [:sport],
            neighborhoods: [create(:neighborhood, user: author)],
            metadata: { landscape_url: "outings/#{SecureRandom.hex(6)}.jpg" }
        end
      end

      def perform_request
        get :index, params: { user_id: 'me', token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['outings'].size
      end
    end
  end
end
