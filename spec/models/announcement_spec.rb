require 'rails_helper'

RSpec.describe Announcement, type: :model do
  it { should validate_presence_of(:title) }
  it { should allow_value(nil).for(:webapp_url) }
  it { should_not allow_value('foo').for(:webapp_url) }
  it { should allow_value('https://entourage.social').for(:webapp_url) }

  describe 'webapp_url' do
    let(:announcement) { FactoryBot.create(:announcement, user_goals: [:offer_help], areas: [:dep_75], webapp_url: webapp_url) }

    describe 'nil' do
      let(:webapp_url) { nil }
      it { expect(announcement.save).to be(true) }
      it { expect(announcement.reload.webapp_url).to eq(nil) }
    end

    describe 'empty string' do
      let(:webapp_url) { '' }
      it { expect(announcement.save).to be(true) }
      it { expect(announcement.reload.webapp_url).to eq(nil) }
    end

    describe 'valid url' do
      let(:webapp_url) { 'https://entourage.social' }
      it { expect(announcement.save).to be(true) }
      it { expect(announcement.reload.webapp_url).to eq(webapp_url) }
    end
  end
end
