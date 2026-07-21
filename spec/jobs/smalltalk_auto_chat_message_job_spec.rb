require 'rails_helper'

RSpec.describe SmalltalkAutoChatMessageJob do
  around { |example| Sidekiq::Testing.disable!(&example) }

  let(:entourage_user) { create(:user) }
  let(:smalltalk) { create(:smalltalk) }

  before { allow(User).to receive(:find_entourage_user).and_return(entourage_user) }

  subject { described_class.new.perform(smalltalk.id, 'complete', '') }

  context 'when smalltalk does not exist' do
    subject { described_class.new.perform(0, 'complete', '') }

    it 'does nothing' do
      expect { subject }.not_to change(ChatMessage, :count)
    end
  end

  context 'when the last chat message is not an auto message' do
    it 'creates an auto chat_message' do
      expect { subject }.to change(ChatMessage, :count).by(1)

      chat_message = ChatMessage.last
      expect(chat_message.message_type).to eq('auto')
      expect(chat_message.user).to eq(entourage_user)
      expect(chat_message.messageable).to eq(smalltalk)
    end

    it 'records the event on the smalltalk' do
      subject
      expect(smalltalk.reload.events['complete']).to be_present
    end
  end

  context 'when the last chat message is already an auto message' do
    before { create(:chat_message, messageable: smalltalk, message_type: 'auto') }

    it 'does not create another chat_message' do
      expect { subject }.not_to change(ChatMessage, :count)
    end

    context 'and the smalltalk has been inactive for less than the inactivity delay' do
      it 'postpones scheduled jobs by one day' do
        SmalltalkAutoChatMessageJob.perform_in(1.hour, smalltalk.id, 'complete', '')
        job_before = Sidekiq::ScheduledSet.new.find { |j| j.args.first == smalltalk.id }

        subject

        job_after = Sidekiq::ScheduledSet.new.find { |j| j.args.first == smalltalk.id }
        expect(job_after).to be_present
        expect(job_after.at).to be_within(1.second).of(job_before.at + 1.day)
      end
    end

    context 'and the smalltalk has been inactive for at least the inactivity delay' do
      before { smalltalk.last_chat_message.update!(created_at: 8.days.ago) }

      it 'deletes scheduled jobs for the smalltalk' do
        SmalltalkAutoChatMessageJob.perform_in(1.hour, smalltalk.id, 'complete', '')

        subject

        scheduled_job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == smalltalk.id }
        expect(scheduled_job).to be_nil
      end
    end
  end
end
