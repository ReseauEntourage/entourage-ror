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

  describe "with_validated_profiles" do
    let(:subject) { UserMessageBroadcast.with_validated_profiles(User.all, :ask_for_help).pluck(:id) }

    let(:validation_status) { :validated }
    let(:goal) { :ask_for_help }

    let!(:user) { create(:user, deleted: false, validation_status: validation_status, goal: goal) }

    context "status is accepted" do
      it { expect(subject).to include(user.id) }
    end

    context "status is deleted" do
      let(:validation_status) { :deleted }

      it { expect(subject).not_to include(user.id) }
    end
  end

  describe "with_engagement" do
    let(:subject) { UserMessageBroadcast.with_engagement(User.all, engagement).pluck(:id) }

    let!(:user) { create(:user) }

    describe "search for engagement" do
      let(:engagement) { true }

      context "user has engagement" do
        let!(:denorm_daily_engagement) { create(:denorm_daily_engagement, user: user) }

        it { expect(subject).to include(user.id) }
      end

      context "user has no engagement" do
        it { expect(subject).not_to include(user.id) }
      end
    end

    describe "search no for engagement" do
      let(:engagement) { false }

      context "user has engagement" do
        let!(:denorm_daily_engagement) { create(:denorm_daily_engagement, user: user) }

        it { expect(subject).not_to include(user.id) }
      end

      context "user has no engagement" do
        it { expect(subject).to include(user.id) }
      end
    end

    describe "do not search for engagement" do
      let(:engagement) { nil }

      context "user has engagement" do
        let!(:denorm_daily_engagement) { create(:denorm_daily_engagement, user: user) }

        it { expect(subject).to include(user.id) }
      end

      context "user has no engagement" do
        it { expect(subject).to include(user.id) }
      end
    end
  end

  describe "created_after" do
    let(:subject) { UserMessageBroadcast.created_after(User.all, 1.day.ago).pluck(:id) }

    let(:created_at) { 1.hour.ago }

    let!(:user) { create(:user, created_at: created_at) }

    context "created_at is recent" do
      it { expect(subject).to include(user.id) }
    end

    context "created_at is old" do
      let(:created_at) { 2.days.ago }

      it { expect(subject).not_to include(user.id) }
    end
  end

  describe "engaged_after" do
    let(:subject) { UserMessageBroadcast.engaged_after(User.all, 1.day.ago).pluck(:id) }

    let(:engaged_at) { 1.hour.ago }

    let!(:user) { create(:user) }
    let!(:denorm_daily_engagement) { create(:denorm_daily_engagement, user: user, date: engaged_at) }

    context "engaged_at is recent" do
      it { expect(subject).to include(user.id) }
    end

    context "engaged_at is old" do
    let(:engaged_at) { 2.days.ago }

      it { expect(subject).not_to include(user.id) }
    end
  end

  describe "with_interests" do
    let(:subject) { UserMessageBroadcast.with_interests(User.all, ['cuisine', 'jeux']).pluck(:id) }

    let(:interests) { ['jeux', 'sport'] }

    let!(:user) { create(:user, interest_list: interests) }

    context "one common interest" do
      it { expect(subject).to include(user.id) }
    end

    context "no common interest" do
      let(:interests) { ['nature', 'sport'] }

      it { expect(subject).not_to include(user.id) }
    end

    context "user has no interest" do
      let(:interests) { [] }

      it { expect(subject).not_to include(user.id) }
    end

    context "broadcast on no interest" do
      let(:subject) { UserMessageBroadcast.with_interests(User.all, []).pluck(:id) }

      it { expect(subject).to include(user.id) }
    end

    context "broadcast on blank interest" do
      let(:subject) { UserMessageBroadcast.with_interests(User.all, ["", nil]).pluck(:id) }

      it { expect(subject).to include(user.id) }
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
