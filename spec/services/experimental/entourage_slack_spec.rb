require 'rails_helper'

describe Experimental::EntourageSlack do
  let(:entourage) { create :entourage, country: :fr, postal_code: "44000" }

  before { described_class.stub(:enable_callback) { true } }

  # verify async method is reachable
  context "async" do
    after { entourage }

    it { expect(described_class).to receive(:notify) }
  end
end
