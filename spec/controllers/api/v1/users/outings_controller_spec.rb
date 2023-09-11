require 'rails_helper'

describe Api::V1::Users::OutingsController, :type => :controller do
  render_views

  let(:user) { FactoryBot.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not logged in" do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      let!(:outing_created) { FactoryBot.create(:outing, user: user, title: "bar", participants: [user],
        metadata: {
          starts_at: 25.days.ago,
          ends_at: 25.days.ago + 1.minute
        }
      )}
      let!(:outing_joined) { FactoryBot.create(:outing, title: "foo", participants: [user],
        metadata: {
          starts_at: 1.month.ago,
          ends_at: 1.month.ago + 1.minute
        }
      )}
      let!(:outing_not_member) { FactoryBot.create(:outing,
        metadata: {
          starts_at: 1.month.ago,
          ends_at: 1.month.ago + 1.minute
        }
      )}
      let!(:outing_in_future) { FactoryBot.create(:outing, participants: [user],
        metadata: {
          starts_at: 1.day.from_now,
          ends_at: 1.day.from_now + 1.minute
        }
      )}

      before { get :past, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result["outings"].count).to eq(2) }
      it { expect(result["outings"].map {|outings| outings["id"]}).to eq([outing_joined.id, outing_created.id]) }
    end
  end
end
