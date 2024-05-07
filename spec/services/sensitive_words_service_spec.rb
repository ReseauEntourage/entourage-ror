require 'rails_helper'

describe SensitiveWordsService do
  let(:entourage) { create :entourage, title: :title, description: :description }

  before { described_class.stub(:enable_callback) { true } }

  # verify async method is reachable
  # @see app/services/sensitive_words_service#check_sensitive_words
  context "async" do
    after { entourage }

    it { expect(described_class).to receive(:analyze_entourage) }
  end
end
