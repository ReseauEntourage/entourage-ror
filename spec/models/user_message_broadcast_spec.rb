require 'rails_helper'

RSpec.describe UserMessageBroadcast, type: :model do
  it { should validate_presence_of(:area_type) }
  it { should validate_presence_of(:goal) }
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:title) }

  describe "areas" do
    let(:subject) { FactoryBot.build(:user_message_broadcast, area_type: area_type, areas: areas).save }
    let(:area_type) { 'list' }

    context "not empty" do
      let(:areas) { [] }
      it { expect(subject).to be false }
    end

    context "invalid format with one area" do
      let(:areas) { ['1'] }
      it { expect(subject).to be false }
    end

    context "another invalid format with one area" do
      let(:areas) { ['321'] }
      it { expect(subject).to be false }
    end

    context "valid format with one area" do
      let(:areas) { ['11'] }
      it { expect(subject).to be true }
    end

    context "valid format with multiple areas" do
      let(:areas) { ['11', '92'] }
      it { expect(subject).to be true }
    end

    context "some valid formats, some invalid formats" do
      let(:areas) { ['11', '321', '92'] }
      it { expect(subject).to be false }
    end
  end

  describe "users & user_ids" do
    let(:subjects) { user_message_broadcast.users }
    let(:subject_ids) { user_message_broadcast.user_ids.sort }

    let!(:moderation_area) { FactoryBot.create(:moderation_area, departement: '75') }
    let(:users) {
      FactoryBot.create_list(:public_user, 5, goal: :ask_for_help)
    }

    let!(:addresses) {
      ['44000', '44240', '75000', '75001', '35100'].map.with_index do |postal_code, index|
        FactoryBot.create(:address, postal_code: postal_code, user: users[index])
      end
    }
    let(:user_message_broadcast) {
      FactoryBot.create(:user_message_broadcast, area_type: area_type, areas: areas)
    }

    # default
    let(:area_type) { 'national' }
    let(:areas) { [] }

    context "national" do
      it { expect(subject_ids).to eq(users.map(&:id).sort) }
    end

    context "sans_zone" do
      let(:area_type) { 'sans_zone' }
      it { expect(subject_ids).to eq([]) }
    end

    context "sans_zone avec un utilisateur sans_zone" do
      let!(:user) { FactoryBot.create(:public_user, goal: :ask_for_help)}

      let(:area_type) { 'sans_zone' }
      it { expect(subject_ids).to eq([user.id]) }
    end

    context "hors_zone" do
      let(:area_type) { 'hors_zone' }
      it { expect(subject_ids.count).to eq(3) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['35100', '44000', '44240']) }
    end

    describe "list" do
      context 'area is contained in a postal_code but does not start the same' do
        let(:area_type) { 'list' }
        let(:areas) { ['50'] }

        it { expect(subject_ids.count).to eq(0) }
        it { expect(subjects.map(&:postal_code).sort).to eq([]) }
      end

      context 'single departement' do
        let(:area_type) { 'list' }
        let(:areas) { ['44'] }

        it { expect(subject_ids.count).to eq(2) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['44000', '44240']) }
      end

      context 'multiple departements all matching' do
        let(:area_type) { 'list' }
        let(:areas) { ['44', '75'] }

        it { expect(subject_ids.count).to eq(4) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['44000', '44240', '75000', '75001']) }
      end

      context 'multiple departements not all matching' do
        let(:area_type) { 'list' }
        let(:areas) { ['44', '00'] }

        it { expect(subject_ids.count).to eq(2) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['44000', '44240']) }
      end

      context 'single postal_code' do
        let(:area_type) { 'list' }
        let(:areas) { ['44240'] }

        it { expect(subject_ids.count).to eq(1) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['44240']) }
      end

      context 'multiple postal_codes all matching' do
        let(:area_type) { 'list' }
        let(:areas) { ['44240', '35100'] }

        it { expect(subject_ids.count).to eq(2) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['35100', '44240']) }
      end

      context 'multiple departements not all matching' do
        let(:area_type) { 'list' }
        let(:areas) { ['44240', '12000'] }

        it { expect(subject_ids.count).to eq(1) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['44240']) }
      end

      context 'multiple departements and postal_codes not all matching' do
        let(:area_type) { 'list' }
        let(:areas) { ['44240', '12000', '13', '35', '75002'] }

        it { expect(subject_ids.count).to eq(2) }
        it { expect(subjects.map(&:postal_code).sort).to eq(['35100', '44240']) }
      end
    end
  end
end
