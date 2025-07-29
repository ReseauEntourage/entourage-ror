require 'rails_helper'

describe Api::ApplicationKey do
  describe 'authorised?' do
    before { Rails.env.stub(:test?) { false } }

    context 'known api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: 'api_debug') }
      it { expect(application_key.key_infos).to eq( {version: '1.0', device: 'rspec', device_family: UserApplication::ANDROID, community: 'entourage'}) }
    end

    context 'unknown api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: 'foobar') }
      it { expect(application_key.key_infos).to be nil }
    end
  end
end
