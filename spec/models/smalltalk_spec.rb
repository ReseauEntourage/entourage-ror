require 'rails_helper'

RSpec.describe Smalltalk, type: :model do
  let(:smalltalk) { create(:smalltalk) }

  describe 'associations' do
    it { should have_many(:user_smalltalks) }
    it { should have_many(:chat_messages) }
    it { should have_one(:last_chat_message) }
    it { should have_one(:chat_messages_count) }
    it { should have_many(:parent_chat_messages) }
    it { should belong_to(:meeting).optional }
  end

  describe 'enums' do
    it { should define_enum_for(:match_format).with_values(one: 0, many: 1) }
  end

  describe 'callbacks' do
    it 'creates a meeting after creation' do
      expect { create(:smalltalk) }.to change(Meeting, :count).by(1)
    end
  end

  describe 'scopes' do
    describe '.matchable' do
      let!(:matchable_smalltalk) { create(:smalltalk, match_format: :many, number_of_people: 3) }
      let!(:one_format_smalltalk) { create(:smalltalk, match_format: :one, number_of_people: 2) }
      let!(:full_smalltalk) { create(:smalltalk, match_format: :many, number_of_people: 5) }

      it 'returns smalltalks with many format and less than 5 people' do
        expect(Smalltalk.matchable).to include(matchable_smalltalk)
        expect(Smalltalk.matchable).not_to include(one_format_smalltalk)
        expect(Smalltalk.matchable).not_to include(full_smalltalk)
      end
    end
  end

  describe '#group_type' do
    it 'returns "smalltalk"' do
      expect(smalltalk.group_type).to eq('smalltalk')
    end
  end

  describe '#group_type_config' do
    it 'returns the expected configuration hash' do
      expected_config = {
        'message_types' => ['text', 'share'],
        'roles' => ['member']
      }
      expect(smalltalk.group_type_config).to eq(expected_config)
    end
  end

  describe '#user' do
    it 'returns nil' do
      expect(smalltalk.user).to be_nil
    end
  end

  describe '#share_url' do
    context 'when uuid_v2 is present' do
      before do
        smalltalk.update!(uuid_v2: 'test-uuid')
        allow(ENV).to receive(:[]).with('MOBILE_HOST').and_return('https://example.com')
      end

      it 'returns the share URL' do
        expect(smalltalk.share_url).to eq('https://example.com/app/smalltalks/test-uuid')
      end
    end

    context 'when uuid_v2 is blank' do
      before { smalltalk.update!(uuid_v2: nil) }

      it 'returns nil' do
        expect(smalltalk.share_url).to be_nil
      end
    end
  end

  describe '#meeting_url' do
    context 'when meeting is present' do
      let(:meeting) { create(:meeting, meet_link: 'https://meet.example.com/123') }
      before { smalltalk.update!(meeting: meeting) }

      it 'returns the meeting URL' do
        expect(smalltalk.meeting_url).to eq('https://meet.example.com/123')
      end
    end

    context 'when meeting is not present' do
      before { smalltalk.update!(meeting: nil) }

      it 'returns nil' do
        expect(smalltalk.meeting_url).to be_nil
      end
    end
  end

  describe '#create_meeting' do
    let(:user1) { create(:user, first_name: 'John', email: 'john@example.com') }
    let(:user2) { create(:user, first_name: 'Jane', email: 'jane@example.com') }
    
    before do
      allow(smalltalk).to receive(:accepted_members).and_return([user1, user2])
    end

    it 'creates a meeting with correct attributes' do
      Timecop.freeze do
        smalltalk.create_meeting
        
        expect(smalltalk.meeting).to be_present
        expect(smalltalk.meeting.title).to eq('John, Jane')
        expect(smalltalk.meeting.participant_emails).to eq(['john@example.com', 'jane@example.com'])
        expect(smalltalk.meeting.start_time).to eq(1.week.from_now)
        expect(smalltalk.meeting.end_time).to eq(1.week.from_now + 1.hour)
      end
    end
  end

  describe '#complete?' do
    context 'when smalltalk is complete' do
      before do
        allow(smalltalk).to receive(:incomplete?).and_return(false)
      end

      it 'returns true' do
        expect(smalltalk.complete?).to be true
      end
    end

    context 'when smalltalk is incomplete' do
      before do
        allow(smalltalk).to receive(:incomplete?).and_return(true)
      end

      it 'returns false' do
        expect(smalltalk.complete?).to be false
      end
    end
  end

  describe '#incomplete?' do
    context 'when match_format is one' do
      before { smalltalk.update!(match_format: :one) }

      it 'returns true when number_of_people < 2' do
        smalltalk.update!(number_of_people: 1)
        expect(smalltalk.incomplete?).to be true
      end

      it 'returns false when number_of_people >= 2' do
        smalltalk.update!(number_of_people: 2)
        expect(smalltalk.incomplete?).to be false
      end
    end

    context 'when match_format is many' do
      before { smalltalk.update!(match_format: :many) }

      it 'returns true when number_of_people < 5' do
        smalltalk.update!(number_of_people: 4)
        expect(smalltalk.incomplete?).to be true
      end

      it 'returns false when number_of_people >= 5' do
        smalltalk.update!(number_of_people: 5)
        expect(smalltalk.incomplete?).to be false
      end
    end
  end

  describe '#members_has_changed!' do
    it 'calls super and check methods' do
      expect(smalltalk).to receive(:check_members_complete_case!)
      expect(smalltalk).to receive(:check_members_alone_case!)
      
      smalltalk.members_has_changed!
    end
  end

  describe '#check_members_complete_case!' do
    context 'when already completed' do
      before { smalltalk.update!(completed_at: Time.current) }

      it 'does not update completed_at again' do
        expect { smalltalk.check_members_complete_case! }.not_to change { smalltalk.completed_at }
      end
    end

    context 'when not completed and incomplete' do
      before do
        smalltalk.update!(completed_at: nil)
        allow(smalltalk).to receive(:complete?).and_return(false)
      end

      it 'does not update completed_at' do
        expect(smalltalk.check_members_complete_case!).to be_nil
      end
    end

    context 'when not completed and complete' do
      before do
        smalltalk.update!(completed_at: nil)
        allow(smalltalk).to receive(:complete?).and_return(true)
      end

      it 'updates completed_at' do
        expect(smalltalk.check_members_complete_case!).not_to be_nil
      end
    end
  end

  describe '#check_members_alone_case!' do
    context 'when not completed' do
      before { smalltalk.update!(completed_at: nil) }

      it 'does not update closed_at' do
        expect { smalltalk.check_members_alone_case! }.not_to change { smalltalk.closed_at }
      end
    end

    context 'when completed but more than 1 person' do
      before do
        smalltalk.update!(completed_at: Time.current, number_of_people: 2)
      end

      it 'does not update closed_at' do
        expect { smalltalk.check_members_alone_case! }.not_to change { smalltalk.closed_at }
      end
    end

    context 'when completed and only 1 person' do
      before do
        smalltalk.update!(completed_at: Time.current, number_of_people: 1)
      end

      it 'updates closed_at and cancels auto messages' do
        expect(smalltalk).to receive(:cancel_auto_messages!)
        
        Timecop.freeze do
          expect { smalltalk.check_members_alone_case! }.to change { smalltalk.reload.closed_at }
        end
      end
    end
  end

  describe '#cancel_auto_messages!' do
    it 'calls SmalltalkAutoChatMessageJob.cancel_jobs_for_smalltalk with correct id' do
      expect(SmalltalkAutoChatMessageJob).to receive(:cancel_jobs_for_smalltalk).with(smalltalk.id)
      smalltalk.cancel_auto_messages!
    end
  end
end
