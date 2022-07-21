require 'rails_helper'
include CommunityHelper

RSpec.describe JoinRequest, type: :model do
  it { expect(FactoryBot.build(:join_request).save).to be true }
  it { should belong_to :user }
  it { should belong_to :joinable }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :joinable_id }
  it { should validate_presence_of :joinable_type }
  it { should validate_presence_of :status }
  it { should validate_inclusion_of(:status).in_array(["accepted"]) }
  # it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected", "cancelled"]) }

  it "has unique join request per user and tour" do
    user = FactoryBot.create(:pro_user)
    tour = FactoryBot.create(:tour, id: 1)
    entourage = FactoryBot.create(:entourage, id: 1)
    expect(FactoryBot.build(:join_request, user: user, joinable: tour).save).to be true
    expect(FactoryBot.build(:join_request, user: user, joinable: tour).save).to be false
    expect(FactoryBot.build(:join_request, user: user, joinable: entourage).save).to be true
  end

  describe "conversation uuids" do
    let(:user_1) { create :public_user }
    let(:user_2) { create :public_user }

    describe "unique" do
      let!(:conversation_1) { create :conversation, participants: [user_1, user_2] }
      let!(:conversation_2) { create :conversation, participants: [user_1] }
      let(:join_request) { build :join_request, joinable: conversation_2, user: user_2 }
      it { expect { join_request.save! }.to raise_error ActiveRecord::RecordNotUnique, /uuid_v2/ }
    end

    describe "updates whe users are added or removed" do
      let!(:conversation) { create :conversation, participants: [user_1] }
      let(:join_request) { build :join_request, joinable: conversation, user: user_2 }
      it do
        single_user_uuid = conversation.uuid_v2
        join_request.save!
        expect(conversation.reload.uuid_v2).not_to eq single_user_uuid
        join_request.destroy!
        expect(conversation.reload.uuid_v2).to eq single_user_uuid
      end
    end
  end

  describe "join_request_observer" do
    subject { create :join_request, status: status, joinable: joinable }
    let(:entourage) { FactoryBot.create(:entourage) }
    let(:tour) { FactoryBot.create(:tour) }
    let(:conversation) { FactoryBot.create(:conversation) }

    describe "create on entourage" do
      let(:joinable) { entourage }

      context "accepted" do
        let(:status) { :accepted }

        before { expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject }
      end

      context "pending" do
        let(:status) { :pending }

        before { expect_any_instance_of(SlackServices::StackTrace).to receive(:notify) }

        it { subject }
      end
    end

    describe "create on tour" do
      let(:joinable) { tour }

      context "accepted" do
        let(:status) { :accepted }

        before { expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject }
      end

      context "pending" do
        let(:status) { :pending }

        before { expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject }
      end
    end

    describe "create on conversation" do
      let(:joinable) { conversation }

      context "accepted" do
        let(:status) { :accepted }

        before { expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject }
      end

      context "pending" do
        let(:status) { :pending }

        before { expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject }
      end
    end

    describe "update on entourage" do
      let(:joinable) { entourage }

      context "from accepted to rejected" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :rejected) }
      end

      context "from accepted to pending" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end

      context "from pending to pending" do
        let(:status) { :pending }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end
    end

    describe "update on tour" do
      let(:joinable) { tour }

      context "from accepted to rejected" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :rejected) }
      end

      context "from accepted to pending" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end

      context "from pending to pending" do
        let(:status) { :pending }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end
    end

    describe "update on conversation" do
      let(:joinable) { conversation }

      context "from accepted to rejected" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :rejected) }
      end

      context "from accepted to pending" do
        let(:status) { :accepted }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end

      context "from pending to pending" do
        let(:status) { :pending }

        before { subject; expect_any_instance_of(SlackServices::StackTrace).not_to receive(:notify) }

        it { subject.update_attribute(:status, :pending) }
      end
    end
  end
end
