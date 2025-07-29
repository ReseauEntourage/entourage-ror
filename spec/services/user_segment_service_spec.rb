require 'rails_helper'

describe UserSegmentService do
  describe 'at_day' do
    describe 'default scoping' do
      describe 'user' do
        let!(:user) { create :public_user, user_attributes.merge(last_sign_in_at: 1.day.ago) }
        let(:user_attributes) { {} }
        let(:segment) { UserSegmentService.at_day(1, after: :last_session) }

        context 'common case' do
          it { expect(segment.pluck(:id)).to include user.id }
        end

        context 'deleted user' do
          let(:user_attributes) { {deleted: true} }
          it { expect(segment.pluck(:id)).not_to include user.id }
        end

        context 'other community' do
          let(:user_attributes) { {community: :pfp} }
          it { expect(segment.pluck(:id)).not_to include user.id }
        end

        context 'blank email' do
          let(:user_attributes) { {email: ''} }
          it { expect(segment.pluck(:id)).not_to include user.id }
        end
      end
    end

    describe 'registration' do
      let(:n) { 3 }
      let!(:user) { create :public_user, user_attributes }
      let(:segment) { UserSegmentService.at_day(n, after: :registration) }

      context 'the user registered at the target date' do
        let(:user_attributes) { {onboarding_sequence_start_at: n.days.ago} }
        it { expect(segment.pluck(:id)).to include user.id }
      end

      context "the user didn't register at the target date" do
        let(:user_attributes) { {onboarding_sequence_start_at: (n + 1).days.ago} }
        it { expect(segment.pluck(:id)).not_to include user.id }
      end
    end

    describe 'last_session' do
      let(:n) { 5 }
      let!(:user) { create :public_user, user_attributes }
      let(:segment) { UserSegmentService.at_day(n, after: :last_session) }

      context 'the user registered at the target date' do
        let(:user_attributes) { {last_sign_in_at: n.days.ago} }
        it { expect(segment.pluck(:id)).to include user.id }
      end

      context "the user didn't register at the target date" do
        let(:user_attributes) { {last_sign_in_at: (n + 1).days.ago} }
        it { expect(segment.pluck(:id)).not_to include user.id }
      end

    end

    describe 'action_creation' do
      let(:n) { 9 }

      let!(:group) { create :entourage, {created_at: n.days.ago, user: user}.merge(group_attributes) }
      let(:group_attributes) { {} }

      let!(:user) { create :public_user, user_attributes }
      let(:user_attributes) { {} }

      let(:segment) { UserSegmentService.at_day(n, after: :action_creation) }

      context 'the action was created at the target date' do
        let(:group_attributes) { {created_at: n.days.ago} }
        it { expect(segment.pluck(:id)).to include group.id }
      end

      context 'the action was not created at the target date' do
        let(:group_attributes) { {created_at: (n - 1).days.ago} }
        it { expect(segment.pluck(:id)).not_to include group.id }
      end

      context 'the group is not an action' do
        let(:group_attributes) { {group_type: :conversation} }
        it { expect(segment.pluck(:id)).not_to include group.id }
      end

      context 'the owner is not in the default user scope' do
        let(:user_attributes) { {email: ''} }
        it { expect(segment.pluck(:id)).not_to include group.id }
      end
    end

    describe 'event' do
      let(:n) { 8 }

      let!(:group) { create :outing, {metadata: {starts_at: n.day.from_now}}.merge(group_attributes) }
      let(:group_attributes) { {} }

      let!(:organizer)   { create :public_user, user_attributes }
      let!(:participant) { create :public_user, user_attributes }
      let(:user_attributes) { {} }

      let!(:organizer_participation)   { create :join_request, {user: organizer,   joinable: group, status: :accepted, role: :organizer}.merge(participation_attributes) }
      let!(:participant_participation) { create :join_request, {user: participant, joinable: group, status: :accepted, role: :participant, requested_at: 1.day.ago}.merge(participation_attributes) }
      let(:participation_attributes) { {} }

      describe 'organizer' do
        let(:segment) { UserSegmentService.at_day(n, before: :event, role: :organizer) }

        context 'valid event' do
          let(:group_attributes) { {metadata: {starts_at: n.day.from_now} } }
          it { expect(segment.pluck(:user_id)).to eq [organizer.id] }
        end

        context 'event at another date' do
          let(:group_attributes) { {metadata: {starts_at: (n - 10).day.from_now} } }
          it { expect(segment.pluck(:user_id)).to eq [] }
        end

        context 'user is not in the default user scope' do
          let(:user_attributes) { {deleted: true} }
          it { expect(segment.pluck(:user_id)).to eq [] }
        end

        context 'event end date' do
          let(:segment) { UserSegmentService.at_day(n, after: :event, role: :organizer) }
          let(:group_attributes) { {metadata: {starts_at: (n + 3).day.ago, ends_at: n.day.ago} } }
          it { expect(segment.pluck(:user_id)).to eq [organizer.id] }
        end
      end

      describe 'participant' do
        let(:segment) { UserSegmentService.at_day(n, before: :event, role: :participant) }

        context 'valid event' do
          let(:group_attributes) { {metadata: {starts_at: n.day.from_now} } }
          it { expect(segment.pluck(:user_id)).to eq [participant.id] }
        end

        context 'valid event with a valid previous_at' do
          let(:group_attributes) { {metadata: {starts_at: n.day.from_now, previous_at: 2.days.ago} } }
          it { expect(segment.pluck(:user_id)).to eq [participant.id] }
        end

        context 'valid event with an invalid previous_at' do
          let(:group_attributes) { {metadata: {starts_at: n.day.from_now, previous_at: 2.hour.ago} } }
          it { expect(segment.pluck(:user_id)).to eq [] }
        end

        context 'join request is not accepted' do
          let(:participation_attributes) { {status: :cancelled} }
          it { expect(segment.pluck(:user_id)).to eq [] }
        end

        context 'the group is not an event' do
          let(:group_attributes) { {group_type: :conversation, metadata: {}, default_metadata: {}} }
          let(:participation_attributes) { {role: :participant} }
          it { expect(segment.pluck(:user_id)).to eq [] }
        end
      end
    end
  end
end
