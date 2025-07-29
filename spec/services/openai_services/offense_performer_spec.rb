require 'rails_helper'

describe OpenaiServices::BasicPerformer do
  let!(:openai_assistant) { create(:openai_assistant, module_type: 'offense', api_key: 'test_key', assistant_id: 'assistant_123', max_prompt_tokens: 100, max_completion_tokens: 200) }
  let(:openai_request) { create(:openai_request, module_type: 'offense') }
  let(:client) { instance_double(OpenAI::Client) }
  let(:thread_id) { 'thread_123' }
  let(:run_id) { 'run_456' }
  let(:assistant_message) { { 'id' => 'message_789', 'content' => [{ 'type' => 'text', 'text' => { 'value' => '{"result":"true"}' } }], 'role' => 'assistant', 'thread_id' => thread_id, 'run_id' => run_id } }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(client)

    allow(client).to receive_message_chain(:threads, :create).and_return({ 'id' => thread_id })
    allow(client).to receive_message_chain(:messages, :create).and_return({ 'id' => 'user_message_id' })
    allow(client).to receive_message_chain(:runs, :create).and_return({ 'id' => run_id })
    allow(client).to receive_message_chain(:runs, :retrieve).and_return({ 'status' => 'completed' })
    allow(client).to receive_message_chain(:messages, :list).and_return({ 'data' => [assistant_message] })
  end

  # not such unit rspec: we want to verify the global process from recording an openai_request to sending an alert on slack
  describe '#perform' do
    subject { openai_request.performer_instance.perform }

    context 'when the process succeeds' do
      let(:offensive_text_service) { instance_double(SlackServices::OffensiveText) }

      before do
        allow(SlackServices::OffensiveText).to receive(:new).and_return(offensive_text_service)
        allow(offensive_text_service).to receive(:notify)
      end

      it 'calls the client methods and updates the openai_request' do
        expect { subject }.to change { openai_request.reload.status }.from(nil).to('success')

        expect(openai_request.response).to be_present
        expect(openai_request.openai_thread_id).to eq(thread_id)
        expect(openai_request.openai_run_id).to eq(run_id)
        expect(SlackServices::OffensiveText).to have_received(:new).with(chat_message_id: openai_request.instance.id, text: openai_request.instance.content)
        expect(offensive_text_service).to have_received(:notify)
      end
    end

    context 'when the run fails' do
      before do
        allow(client).to receive_message_chain(:runs, :retrieve).and_return({ 'status' => 'failed' })
      end

      it 'handles failure and updates the request status to error' do
        expect { subject }.to change { openai_request.reload.status }.from(nil).to('error')

        expect(openai_request.error).to eq('Failure status failed')
      end
    end

    context 'when the response is invalid' do
      before do
        allow(client).to receive_message_chain(:messages, :list).and_return({ 'data' => [] }) # No assistant message
      end

      it 'handles failure due to invalid response' do
        expect { subject }.to change { openai_request.reload.status }.from(nil).to('error')

        expect(openai_request.error).to eq('Response not valid')
      end
    end

    context 'when an exception occurs' do
      before do
        allow(client).to receive_message_chain(:threads, :create).and_raise(StandardError, 'Unexpected error')
      end

      it 'handles the exception and updates the request status to error' do
        expect { subject }.to change { openai_request.reload.status }.from(nil).to('error')

        expect(openai_request.error).to eq('Unexpected error')
      end
    end
  end
end
