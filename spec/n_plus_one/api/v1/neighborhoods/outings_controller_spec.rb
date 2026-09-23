require 'rails_helper'

describe Api::V1::Neighborhoods::OutingsController, type: :controller do
  let(:user) { create :public_user }
  let(:neighborhood) { create :neighborhood, participants: [user] }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : translations, users (auteur), partners, tags, neighborhoods, outing_recurrences, member_ids et confirmed_member_ids par événement (aucun preload dans le contrôleur, V1::OutingSerializer)' do
      def populate(count)
        count.times do
          author = create :public_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}")
          # l'auteur doit être membre du groupe pour y rattacher l'événement
          create :join_request, joinable: neighborhood, user: author, status: JoinRequest::ACCEPTED_STATUS

          create :outing, :with_recurrence,
            user: author,
            neighborhoods: [neighborhood],
            participants: [create(:public_user)],
            interest_list: [:sport],
            metadata: { landscape_url: "outings/#{SecureRandom.hex(6)}.jpg" }
        end
      end

      def perform_request
        get :index, params: { token: user.token, neighborhood_id: neighborhood.to_param }
      end

      def returned_items_count
        JSON.parse(response.body)['outings'].size
      end
    end
  end
end
