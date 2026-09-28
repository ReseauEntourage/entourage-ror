require 'rails_helper'

# Les serializers V1 utilisent lazy_relationship (ams_lazy_relationships), qui s'appuie sur
# BatchLoader : son cache est stocké dans le thread courant et doit être vidé à la fin de chaque
# requête (BatchLoader::Middleware), sinon un thread Puma resert des valeurs chargées par une
# requête précédente.
describe 'BatchLoader cache between API requests', type: :request do
  let(:user) { create :public_user }
  let(:participant) { create :public_user }
  let!(:conversation) { create :conversation, participants: [user, participant] }

  def last_message_text
    get '/api/v1/conversations', params: { token: user.token }

    JSON.parse(response.body)['conversations']
      .find { |item| item['id'] == conversation.id }
      .dig('last_message', 'text')
  end

  it 'is cleared at the end of each request' do
    create :chat_message, messageable: conversation, user: participant

    get '/api/v1/conversations', params: { token: user.token }

    expect(JSON.parse(response.body)['conversations'].map { |item| item['id'] }).to eq([conversation.id])
    expect(BatchLoader::Executor.current).to be_nil
  end

  it 'does not serve a last message loaded by a previous request' do
    create :chat_message, messageable: conversation, user: participant, content: 'first', created_at: 2.minutes.ago
    expect(last_message_text).to eq('first')

    create :chat_message, messageable: conversation, user: participant, content: 'second', created_at: 1.minute.ago
    expect(last_message_text).to eq('second')
  end
end
