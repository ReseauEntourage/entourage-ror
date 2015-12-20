require 'rails_helper'

describe Api::ApplicationKey do
  describe 'authorised?' do
    context "known api key" do
      let(:application_key) { Api::ApplicationKey.new(api_key: "api_debug") }
      it { expect(application_key.authorised?).to be true }
    end

    context "known api key" do
      let(:application_key) { Api::ApplicationKey.new(api_key: "foobar") }
      it { expect(application_key.authorised?).to be false }
    end
  end
end