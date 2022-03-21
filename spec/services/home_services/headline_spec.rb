require 'rails_helper'

describe HomeServices::Headline do
  let(:user) { FactoryBot.create(:pro_user_paris) }

  describe 'find_pin' do
    let!(:pin) { FactoryBot.create(:entourage, pin: true, pins: ['75']) }

    let(:subject) { HomeServices::Headline.new(user: user, latitude: nil, longitude: nil) }

    it 'should find a pin' do
      expect(Entourage).to receive(:find_by).with(id: pin.id)

      subject.find_pin
    end

    it 'should not find a pin without valid postal_code' do
      user.address.update_attribute(:postal_code, '00000')

      expect(Entourage).not_to receive(:find_by)
      expect(
        subject.find_pin
      ).to be_nil
    end
  end

  describe 'find_announcement' do
    let!(:announcement) { FactoryBot.create(:announcement, user_goals: ['goal_not_known'], areas: ['dep_75']) }

    let(:subject) { HomeServices::Headline.new(user: user, latitude: nil, longitude: nil) }

    it 'should find default announcement' do
      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(subject.find_announcement).to eq(announcement)
    end

    it 'should find nil if no default announcement' do
      announcement.update_attribute(:category, :foo)

      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(subject.find_announcement).to be_nil
    end

    it 'should find announcement with a given category' do
      announcement.update_attribute(:category, :foo)

      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      expect(subject.find_announcement(category: :foo)).to eq(announcement)
    end
  end

  describe 'find_outing' do
    # outing coordinates: (48.854367553785, 2.27034058909627)
    let!(:outing) { FactoryBot.create(:outing) }
    let!(:second) { FactoryBot.create(:outing) }

    # 3,092km from outing
    let(:subject) { HomeServices::Headline.new(user: user, latitude: 48.83, longitude: 2.25) }

    it 'should find an outing' do
      expect(subject.find_outing).to eq(outing)
    end

    it 'should find an outing within user travel_distance' do
      user.update_attribute(:travel_distance, 8)

      expect(subject.find_outing).to eq(outing)
    end

    it 'should not find an outing outside user travel_distance' do
      user.update_attribute(:travel_distance, 2)

      expect(subject.find_outing).to be_nil
    end

    it 'should not find a closed outing' do
      outing.update_attribute(:status, :closed)
      second.update_attribute(:status, :closed)

      expect(subject.find_outing).to be_nil
    end

    it 'should find an offset outing' do
      expect(subject.find_outing(offset: 1)).to eq(second)
    end
  end

  describe 'find_action' do
    # action coordinates: 1.122, 2.345
    let!(:action) { FactoryBot.create(:entourage) }
    let!(:second) { FactoryBot.create(:entourage) }

    # 5,57km from action
    let(:subject) { HomeServices::Headline.new(user: user, latitude: 1.1, longitude: 2.3) }

    it 'should find an action' do
      expect(subject.find_action).to eq(second) # created_at desc
    end

    it 'should find an action within user travel_distance' do
      user.update_attribute(:travel_distance, 8)

      expect(subject.find_action).to eq(second)
    end

    it 'should not find an action outside user travel_distance' do
      user.update_attribute(:travel_distance, 2)

      expect(subject.find_action).to be_nil
    end

    it 'should find an offset action' do
      expect(subject.find_action(offset: 1)).to eq(action) # created_at desc
    end
  end

  describe 'each' do
    let!(:pin) { FactoryBot.create(:entourage, pin: true, pins: ['75']) }
    let!(:announcement_0) { FactoryBot.create(:announcement, id: 1, position: 1, user_goals: ['goal_not_known'], areas: ['dep_75']) }
    let!(:announcement_1) { FactoryBot.create(:announcement, id: 2, position: 2, user_goals: ['goal_not_known'], areas: ['dep_75']) }
    let!(:announcement_2) { FactoryBot.create(:announcement, id: 6, position: 6, user_goals: ['goal_not_known'], areas: ['dep_75']) }
    let!(:announcement_online) { FactoryBot.create(:announcement, id: 3, position: 3, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :online) }
    let!(:announcement_poi_map) { FactoryBot.create(:announcement, id: 4, position: 4, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :poi_map) }
    let!(:announcement_ambassador) { FactoryBot.create(:announcement, id: 5, position: 5, user_goals: ['goal_not_known'], areas: ['dep_75'], category: :ambassador) }
    let!(:outing) { FactoryBot.create(:outing) }
    let!(:action) { FactoryBot.create(:entourage, latitude: 48.854367553784954, longitude: 2.270340589096274) }
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
      expect(headlines[0][:name]).to eq(:pin)
      expect(headlines[0][:instance]).to eq(pin)
      # announcement_0
      expect(headlines[1][:type]).to eq('Announcement')
      expect(headlines[1][:name]).to eq(:announcement_0)
      expect(headlines[1][:instance]).to eq(announcement_0)
      # announcement_1
      expect(headlines[2][:type]).to eq('Announcement')
      expect(headlines[2][:name]).to eq(:announcement_1)
      expect(headlines[2][:instance]).to eq(announcement_1)
      # announcement_2
      expect(headlines[3][:type]).to eq('Announcement')
      expect(headlines[3][:name]).to eq(:announcement_2)
      expect(headlines[3][:instance]).to eq(announcement_2)
      # announcement_online
      expect(headlines[4][:type]).to eq('Announcement')
      expect(headlines[4][:name]).to eq(:announcement_online)
      expect(headlines[4][:instance]).to eq(announcement_online)
    end

    it 'ask_for_help & dead' do
      allow(ModerationArea).to receive(:all_slugs) { [:dep_75] }
      allow(user).to receive(:departement_slugs) { [:dep_75] }

      allow(headline).to receive(:profile) { :ask_for_help }
      allow(headline).to receive(:zone) { :dead }

      headlines = []
      headline.each { |line| headlines << line }

      expect(headlines).to be_a(Array)
      expect(headlines.count).to eq(5)

      # pin
      expect(headlines[0][:type]).to eq('Entourage')
      expect(headlines[0][:name]).to eq(:pin_neighborhood)
      expect(headlines[0][:instance]).to eq(pin)
      # announcement_0
      expect(headlines[1][:type]).to eq('Announcement')
      expect(headlines[1][:name]).to eq(:announcement_0)
      expect(headlines[1][:instance]).to eq(announcement_0)
      # announcement_1
      expect(headlines[2][:type]).to eq('Announcement')
      expect(headlines[2][:name]).to eq(:announcement_1)
      expect(headlines[2][:instance]).to eq(announcement_1)
      # announcement_2
      expect(headlines[3][:type]).to eq('Announcement')
      expect(headlines[3][:name]).to eq(:announcement_2)
      expect(headlines[3][:instance]).to eq(announcement_2)
      # announcement_online
      expect(headlines[4][:type]).to eq('Announcement')
      expect(headlines[4][:name]).to eq(:announcement_online)
      expect(headlines[4][:instance]).to eq(announcement_online)
    end
  end
end
