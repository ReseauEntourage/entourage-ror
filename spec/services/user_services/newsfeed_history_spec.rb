
require 'rails_helper'

RSpec.describe UserServices::NewsfeedHistory do

  let(:user) { FactoryBot.create(:public_user) }

  describe 'save' do
    describe "save newsfeed to history" do
      before { described_class.save(user: user, latitude: 2.35, longitude: 45.67) }
      it { expect(UserNewsfeed.count).to eq(1) }
    end

    describe "delete olds newsfeed" do
      before { described_class.const_set("NEWSFEED_KEEP", 2) }
      let!(:previous_newsfeed) { FactoryBot.create_list(:user_newsfeed, 3, user: user) }
      before { described_class.save(user: user, latitude: 2.35, longitude: 45.67) }
      it { expect(UserNewsfeed.count).to eq(2) }
    end
  end
end
