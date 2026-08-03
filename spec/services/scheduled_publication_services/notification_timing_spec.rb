require 'rails_helper'

# Verifies the interaction between scheduled posts and the pre-existing translation/push
# notification pipeline (TranslationObserver -> TranslatorJob -> Translation -> PushNotificationTriggerObserver
# -> PushNotificationTriggerJob -> PushNotificationTrigger#chat_message_on_create/_update, gated by
# ChatMessage#visible?). A scheduled post must NOT notify recipients at creation time, only once it
# actually becomes visible (status: active) at publish time.
describe 'scheduled post notification timing' do
  let!(:author) { create(:public_user) }
  let!(:recipient) { create(:public_user) }
  let!(:neighborhood) { create(:neighborhood, participants: [author, recipient]) }

  it 'does not send a push notification when the post is only scheduled' do
    expect(PushNotificationService).not_to receive(:new)

    message = ChatMessage.create!(messageable: neighborhood, user: author, content: 'hello', status: :scheduled)
    scheduled_publication = create(:scheduled_publication, publishable: message, neighborhood: neighborhood, author: author, scheduled_at: 1.day.from_now)

    expect(message.reload.status).to eq('scheduled')
    scheduled_publication # touch to silence unused warning
  end

  it 'sends a push notification once the scheduled post is actually published' do
    message = ChatMessage.create!(messageable: neighborhood, user: author, content: 'hello', status: :scheduled)
    scheduled_publication = create(:scheduled_publication, publishable: message, neighborhood: neighborhood, author: author, scheduled_at: 1.day.from_now)

    push_service = instance_double(PushNotificationService, send_notification: true)
    allow(PushNotificationService).to receive(:new).and_return(push_service)

    ScheduledPublicationServices::Publisher.new(scheduled_publication).publish!

    expect(message.reload.status).to eq('active')
    expect(push_service).to have_received(:send_notification).at_least(:once)
  end
end
