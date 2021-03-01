require 'rails_helper'
include CommunityHelper

RSpec.describe JoinRequest, type: :model do
  it { expect(FactoryGirl.build(:join_request).save).to be true }
  it { should belong_to :user }
  it { should belong_to :joinable }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :joinable_id }
  it { should validate_presence_of :joinable_type }
  it { should validate_presence_of :status }
  it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected", "cancelled"]) }

  it "has unique join request per user and tour" do
    user = FactoryGirl.create(:pro_user)
    tour = FactoryGirl.create(:tour, id: 1)
    entourage = FactoryGirl.create(:entourage, id: 1)
    expect(FactoryGirl.build(:join_request, user: user, joinable: tour).save).to be true
    expect(FactoryGirl.build(:join_request, user: user, joinable: tour).save).to be false
    expect(FactoryGirl.build(:join_request, user: user, joinable: entourage).save).to be true
  end

  describe "conversation uuids" do
    with_community :pfp
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

  describe "after_save join_request" do
    let(:conversation) { create :conversation }

    describe "no requested_at for accepted" do
      let(:join_request) { create :join_request, joinable: conversation, status: 'accepted' }

      # requested_at should be nil
      it do
        expect(join_request.requested_at).to eq nil
        expect(
          Entourage.find(join_request.joinable_id).max_join_request_requested_at
        ).to eq nil
      end
    end

    describe "requested_at for pending" do
      let(:join_request) { create :join_request, joinable: conversation, status: 'pending' }

      it do
      # requested_at should be a date
        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          Entourage.find(join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end

    describe "from accepted to pending" do
      let(:join_request) { create :join_request, joinable: conversation, status: 'accepted' }

      # requested_at should change from nil to date
      it do
        join_request.update_attribute(:status, 'pending')
        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          Entourage.find(join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end

    describe "from pending to accepted" do
      let(:join_request) { create :join_request, joinable: conversation, status: 'pending' }

      # requested_at should not change but stays a date
      it do
        join_request.update_attribute(:status, 'accepted')
        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          Entourage.find(join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end
  end
end
