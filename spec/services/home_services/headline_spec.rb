require 'rails_helper'

describe HomeServices::Headline do
  let(:user) { FactoryGirl.create(:pro_user_paris) }

  describe 'find_pin' do
    it 'should find a pin' do
      expect(Entourage).to receive(:find).with(110033)

      HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_pin(category: :neighborhood)
    end

    it 'should not find a pin without valid category' do
      expect(Entourage).not_to receive(:find)
      expect(
        HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_pin(category: :foo)
      ).to be_nil
    end

    it 'should not find a pin without valid postal_code' do
      user.address.update_attribute(:postal_code, '00000')

      expect(Entourage).not_to receive(:find)
      expect(
        HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_pin(category: :foo)
      ).to be_nil
    end
  end

  describe 'find_announcement' do
    let!(:announcement) { FactoryGirl.create(:announcement, user_goals: ['goal_not_known'], areas: ['dep_75']) }

    it 'should find default announcement' do
      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(
        HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_announcement
      ).to eq(announcement)
    end

    it 'should find nil if no default announcement' do
      announcement.update_attribute(:category, :foo)

      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(
        HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_announcement
      ).to be_nil
    end

    it 'should find announcement with a given category' do
      announcement.update_attribute(:category, :foo)

      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(
        HomeServices::Headline.new(user: user, latitude: nil, longitude: nil).find_announcement(category: :foo)
      ).to eq(announcement)
    end
  end

  describe 'find_outing' do
    let!(:outing) { FactoryGirl.create(:outing) }
    let!(:second) { FactoryGirl.create(:outing) }

    it 'should find an outing' do
      expect(
        HomeServices::Headline.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274).find_outing
      ).to eq(outing)
    end

    it 'should not find a closed outing' do
      outing.update_attribute(:status, :closed)
      second.update_attribute(:status, :closed)

      expect(
        HomeServices::Headline.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274).find_outing
      ).to be_nil
    end

    it 'should find an offset outing' do
      expect(
        HomeServices::Headline.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274).find_outing(offset: 1)
      ).to eq(second)
    end
  end

  describe 'find_action' do
    let!(:action) { FactoryGirl.create(:entourage) }
    let!(:second) { FactoryGirl.create(:entourage) }

    it 'should find an action' do
      expect(
        HomeServices::Headline.new(user: user, latitude: 1.122, longitude: 2.345).find_action
      ).to eq(second) # created_at desc
    end

    it 'should not find a far action' do
      expect(
        HomeServices::Headline.new(user: user, latitude: 10.122, longitude: 2.345).find_action
      ).to be_nil
    end

    it 'should find an offset action' do
      expect(
        HomeServices::Headline.new(user: user, latitude: 1.122, longitude: 2.345).find_action(offset: 1)
      ).to eq(action) # created_at desc
    end
  end

  describe 'each' do
    let!(:pin) { FactoryGirl.create(:entourage, id: 110033) }
    let!(:announcement_0) { FactoryGirl.create(:announcement, id: 1, user_goals: ['goal_not_known'], areas: ['dep_75']) }
    let!(:announcement_1) { FactoryGirl.create(:announcement, id: 2, user_goals: ['goal_not_known'], areas: ['dep_75']) }
    let!(:announcement_online) { FactoryGirl.create(:announcement, id: 3, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :online) }
    let!(:announcement_poi_map) { FactoryGirl.create(:announcement, id: 4, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :poi_map) }
    let!(:announcement_ambassador) { FactoryGirl.create(:announcement, id: 5, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :ambassador) }
    let!(:outing) { FactoryGirl.create(:outing) }
    let!(:action) { FactoryGirl.create(:entourage, latitude: 48.854367553784954, longitude: 2.270340589096274) }
    let!(:headline) { HomeServices::Headline.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274) }

    it 'offer_help & active' do
      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      allow(headline).to receive(:profile) { :offer_help }
      allow(headline).to receive(:zone) { :active }

      headlines = []
      headline.each { |line| headlines << line }

      expect(headlines).to be_a(Array)
      expect(headlines.count).to eq(5)

      # pin
      expect(headlines[0][:type]).to eq('Entourage')
      expect(headlines[0][:name]).to eq(:pin_neighborhood)
      expect(headlines[0][:instance]).to eq(pin)
      # announcement
      expect(headlines[1][:type]).to eq('Announcement')
      expect(headlines[1][:name]).to eq(:announcement_0)
      expect(headlines[1][:instance]).to eq(announcement_0)
      # outing
      expect(headlines[2][:type]).to eq('Entourage')
      expect(headlines[2][:name]).to eq(:outing)
      expect(headlines[2][:instance]).to eq(outing)
      # action
      expect(headlines[3][:type]).to eq('Entourage')
      expect(headlines[3][:name]).to eq(:action)
      expect(headlines[3][:instance]).to eq(action)
      # announcement
      expect(headlines[4][:type]).to eq('Announcement')
      expect(headlines[4][:name]).to eq(:announcement_1)
      expect(headlines[4][:instance]).to eq(announcement_1)
    end

    it 'ask_for_help & dead' do
      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      allow(headline).to receive(:profile) { :ask_for_help }
      allow(headline).to receive(:zone) { :dead }

      headlines = []
      headline.each { |line| headlines << line }

      expect(headlines).to be_a(Array)
      expect(headlines.count).to eq(3)

      # announcement
      expect(headlines[0][:type]).to eq('Announcement')
      expect(headlines[0][:name]).to eq(:announcement_0)
      expect(headlines[0][:instance]).to eq(announcement_0)
      # outing
      expect(headlines[1][:type]).to eq('Entourage')
      expect(headlines[1][:name]).to eq(:outing)
      expect(headlines[1][:instance]).to eq(outing)
      # announcement
      expect(headlines[2][:type]).to eq('Announcement')
      expect(headlines[2][:name]).to eq(:announcement_poi_map)
      expect(headlines[2][:instance]).to eq(announcement_poi_map)
    end
  end
end
