require 'rails_helper'

RSpec.describe UnreadChatMessageJob do
  let(:user) { create(:public_user) }
  let(:other) { create(:public_user) }
  let(:conversation) { create(:conversation, participants: [user, other]) }
  let(:join_request) { conversation.join_requests.find_by(user: user) }

  subject { described_class.new.perform('Entourage', conversation.id) }

  it 'counts messages created after last_message_read' do
    join_request.update_column(:last_message_read, 1.hour.ago)
    create(:chat_message, messageable: conversation, user: other, created_at: 10.minutes.ago)

    subject

    expect(join_request.reload.unread_messages_count).to eq(1)
  end

  it 'ignores replies (ancestry present)' do
    join_request.update_column(:last_message_read, 1.hour.ago)
    root = create(:chat_message, messageable: conversation, user: other, created_at: 10.minutes.ago)
    create(:chat_message, messageable: conversation, user: other, created_at: 5.minutes.ago, ancestry: root.id.to_s)

    subject

    expect(join_request.reload.unread_messages_count).to eq(1)
  end

  it 'ignores deleted messages' do
    join_request.update_column(:last_message_read, 1.hour.ago)
    create(:chat_message, messageable: conversation, user: other, created_at: 10.minutes.ago, status: 'deleted')

    subject

    expect(join_request.reload.unread_messages_count).to eq(0)
  end

  it 'corrects an out-of-date stored value (e.g. a lost previous run)' do
    join_request.update_column(:last_message_read, 1.hour.ago)
    create(:chat_message, messageable: conversation, user: other, created_at: 10.minutes.ago)
    join_request.update_column(:unread_messages_count, 0)

    expect { subject }.to change { join_request.reload.unread_messages_count }.from(0).to(1)
  end
end
