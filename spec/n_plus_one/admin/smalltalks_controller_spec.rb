require 'rails_helper'
include AuthHelper

describe Admin::SmalltalksController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      # centres d'intérêt distincts par membre : sinon Tag.where(id: ...) est servi par le cache de requêtes
      def next_interests
        @interest_combinations ||= Tag.interest_list.combination(2).to_a
        @interest_combinations.shift
      end

      def populate(count)
        count.times do
          members = 2.times.map do
            member = create(:public_user, interest_list: next_interests)
            member.update!(address: create(:address, user: member))
            member
          end

          smalltalk = create(:smalltalk, participants: members)

          members.each do |member|
            create(:user_smalltalk, user: member, smalltalk: smalltalk, matched_at: Time.now, user_interest_ids: member.interest_ids)
            create(:chat_message, messageable: smalltalk, user: member)
          end
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:smalltalks).to_a.size
      end
    end
  end
end
