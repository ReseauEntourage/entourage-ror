require 'rails_helper'

describe PreferenceServices::UserDefault do

  let(:user) { FactoryBot.create(:pro_user) }

  describe 'date_range' do
    context "has date range saved" do
      before { PreferenceServices::UserDefault.new(user: user).date_range = "22/11/2015-21/12/2015" }
      it { expect(PreferenceServices::UserDefault.new(user: user).date_range).to eq("22/11/2015-21/12/2015") }
    end

    context "no tours" do
      it { expect(PreferenceServices::UserDefault.new(user: user).date_range).to eq("") }
    end
  end

  describe 'latitude' do
    context "has latitude saved" do
      before { PreferenceServices::UserDefault.new(user: user).latitude = 48.858859 }
      it { expect(PreferenceServices::UserDefault.new(user: user).latitude).to eq(48.858859) }
    end

    context "no latitude" do
      it { expect(PreferenceServices::UserDefault.new(user: user).latitude).to eq(48.866051) }
    end
  end

  describe 'longitude' do
    context "has longitude saved" do
      before { PreferenceServices::UserDefault.new(user: user).longitude = 2.34705999 }
      it { expect(PreferenceServices::UserDefault.new(user: user).longitude).to eq(2.34705999) }
    end

    context "no longitude" do
      it { expect(PreferenceServices::UserDefault.new(user: user).longitude).to eq(2.3565218) }
    end
  end
end
