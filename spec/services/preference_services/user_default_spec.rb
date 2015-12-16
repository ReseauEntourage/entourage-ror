require 'rails_helper'

describe PreferenceServices::UserDefault do

  let(:user) { FactoryGirl.create(:user) }

  describe 'snap_to_road' do
    context "true" do
      before { PreferenceServices::UserDefault.new(user: user).snap_to_road = true }
      it { expect(PreferenceServices::UserDefault.new(user: user).snap_to_road).to be true }
    end

    context "false" do
      before { PreferenceServices::UserDefault.new(user: user).snap_to_road = false }
      it { expect(PreferenceServices::UserDefault.new(user: user).snap_to_road).to be false }
    end
  end
end