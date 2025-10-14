require 'rails_helper'

describe OpenaiServices::MatchingResponse do
  describe '#parsed_response' do
    subject { described_class.new(response: response).parsed_response }

    context 'when response is nil' do
      let(:response) { nil }

      it { expect(subject).to be_nil }
    end

    context 'when response has no content' do
      let(:response) { { 'content' => [] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is not "text"' do
      let(:response) { { 'content' => [{ 'type' => 'image', 'text' => { 'value' => '{"key":"value"}' } }] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is "text" but text is malformed' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => 'invalid json' } }] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is "text" and text contains valid JSON' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => '{"key":"value"}' } }] } }

      it { expect(subject).to eq({ 'key' => 'value' }) }
    end

    context 'when text contains extraneous data but valid JSON inside' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => 'Random text before ```json{"key":"value"}``` and after' } }] } }

      it { expect(subject).to eq({ 'key' => 'value' }) }
    end
  end
end
