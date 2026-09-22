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
  it { should validate_inclusion_of(:status).in_array(['accepted']) }
  # it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected", "cancelled"]) }

  it 'has unique join request per user' do
    user = FactoryBot.create(:pro_user)
    entourage = FactoryBot.create(:entourage, id: 1)

    expect(FactoryBot.build(:join_request, user: user, joinable: entourage).save).to be true
  end

  describe 'conversation uuids' do
    let(:user_1) { create :public_user }
    let(:user_2) { create :public_user }

    describe 'unique' do
      let!(:conversation_1) { create :conversation, participants: [user_1, user_2] }
      let!(:conversation_2) { create :conversation, participants: [user_1] }
      let(:join_request) { build :join_request, joinable: conversation_2, user: user_2 }
      it { expect { join_request.save! }.to raise_error ActiveRecord::RecordNotUnique, /uuid_v2/ }
    end

    describe 'updates whe users are added or removed' do
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

  let!(:user) { create(:user, first_name: 'User1') }
  let!(:accepted_creator) { create(:user, first_name: 'Creator') }
  let!(:rejected_organizer) { create(:user, first_name: 'Organizer') }
  let!(:participant) { create(:user, first_name: 'Participant') }
  let!(:neighborhood) { create(:neighborhood, user: accepted_creator, name: 'Test Neighborhood') }
  let!(:outing) { create(:outing, user: accepted_creator, title: 'Test Entourage') }


  describe 'associations' do
    before do
      # create(:join_request, user: accepted_creator, joinable: neighborhood, status: :accepted, role: :creator) # automatically created
      create(:join_request, user: participant, joinable: neighborhood, status: :cancelled, role: :member)

      create(:join_request, user: accepted_creator, joinable: outing, status: :accepted, role: :organizer)
      create(:join_request, user: rejected_organizer, joinable: outing, status: :cancelled, role: :organizer)
      create(:join_request, user: participant, joinable: outing, status: :accepted, role: :participant)
    end

    it 'has many join_requests' do
      expect(neighborhood.join_requests.map(&:user_id)).to match_array([accepted_creator.id, participant.id])
      expect(outing.join_requests.map(&:user_id)).to match_array([accepted_creator.id, rejected_organizer.id, participant.id])
    end

    it 'filters creators_or_organizers correctly' do
      # Vérifie que seul l'utilisateur avec le statut 'accepted' et le rôle 'creator' est retourné
      expect(neighborhood.creators_or_organizer_ids).to eq([accepted_creator.id])
      expect(outing.creators_or_organizer_ids).to eq([accepted_creator.id])
    end

    it 'does not include rejected or non-creator/organizer users in creators_or_organizers' do
      expect(neighborhood.creators_or_organizers).not_to include(rejected_organizer)
      expect(outing.creators_or_organizers).not_to include(rejected_organizer)
    end
  end

  describe 'scopes' do
    let!(:member) { create(:user, first_name: 'Member') }
    let!(:action) { create(:entourage, group_type: :action) }
    let!(:conversation) { create(:conversation, participants: [member]) }
    let!(:smalltalk) { create(:smalltalk, participants: [member]) }

    let!(:action_join_request) { create(:join_request, joinable: action, user: member, status: :accepted, role: :member) }
    let!(:outing_join_request) { create(:join_request, joinable: outing, user: member, status: :accepted, role: :participant) }
    let!(:neighborhood_join_request) { create(:join_request, joinable: neighborhood, user: member, status: :accepted, role: :member) }
    let(:conversation_join_request) { conversation.join_requests.find_by(user: member) }
    let(:smalltalk_join_request) { smalltalk.join_requests.find_by(user: member) }

    let(:member_join_requests) { JoinRequest.where(user: member) }

    describe '.with_conversation_type' do
      it 'returns everything untouched when no type is given' do
        expect(member_join_requests.with_conversation_type(nil)).to match_array(member_join_requests)
      end

      it 'maps "outing" to entourages whose group_type is outing' do
        expect(member_join_requests.with_conversation_type(:outing)).to contain_exactly(outing_join_request)
      end

      it 'maps "conversation" to entourages whose group_type is conversation' do
        expect(member_join_requests.with_conversation_type(:conversation)).to contain_exactly(conversation_join_request)
      end

      it 'does not map "action": actions have no conversation, so they are excluded' do
        expect(member_join_requests.with_conversation_type(:action)).to be_empty
      end

      it 'filters non-Entourage joinable types directly by joinable_type' do
        expect(member_join_requests.with_conversation_type(:Neighborhood)).to contain_exactly(neighborhood_join_request)
      end
    end

    describe '.without_conversation_type' do
      it 'returns everything untouched when no type is given' do
        expect(member_join_requests.without_conversation_type(nil)).to match_array(member_join_requests)
      end

      it 'excludes the given joinable_type' do
        expect(member_join_requests.without_conversation_type(:Neighborhood)).not_to include(neighborhood_join_request)
      end

      it 'only filters by joinable_type, so actions are not excluded' do
        expect(member_join_requests.without_conversation_type(:Neighborhood)).to include(action_join_request)
      end
    end
  end
end
