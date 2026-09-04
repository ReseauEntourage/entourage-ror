require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController do
  let!(:user) { admin_basic_login }

  describe 'GET upcoming' do
    let!(:soon) { FactoryBot.create(:outing, status: 'open', metadata: { starts_at: 3.days.from_now }) }
    let!(:far) { FactoryBot.create(:outing, status: 'open', metadata: { starts_at: 20.days.from_now }) }
    let!(:past) { FactoryBot.create(:outing, status: 'open', metadata: { starts_at: 1.day.ago }) }

    before { get :upcoming, params: { days: 14 } }

    it { expect(response).to be_successful }
    it { expect(assigns(:outings)).to include(soon) }
    it { expect(assigns(:outings)).not_to include(far) }
    it { expect(assigns(:outings)).not_to include(past) }

    it 'orders outings by start date ascending' do
      other_soon = FactoryBot.create(:outing, status: 'open', metadata: { starts_at: 1.day.from_now })
      get :upcoming, params: { days: 14 }

      expect(assigns(:outings).to_a).to eq([other_soon, soon])
    end
  end
end
