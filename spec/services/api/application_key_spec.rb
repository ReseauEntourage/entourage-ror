require 'rails_helper'

describe Api::ApplicationKey do
  describe '#key_infos' do
    before { Rails.env.stub(:test?) { false } }

    context 'known debug api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: 'api_debug') }
      it { expect(application_key.key_infos).to eq(version: '1.0', device: 'rspec', device_family: UserApplication::ANDROID, hmac_secret: 'rspec_hmac_secret') }
    end

    context 'known debug web api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: 'api_debug_web') }
      it { expect(application_key.key_infos).to eq(version: '1.0', device: 'rspec', device_family: UserApplication::WEB, hmac_secret: 'rspec_hmac_secret') }
    end

    context 'the hardcoded web api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: '26fb18404cb9d6afebc87349') }
      it { expect(application_key.key_infos).to eq(version: '5.0.0', device: 'web', device_family: UserApplication::WEB) }
    end

    context 'unknown api key' do
      let(:application_key) { Api::ApplicationKey.new(api_key: 'foobar') }
      it { expect(application_key.key_infos).to be nil }
    end

    it 'never returns a :community field, for any known key' do
      %w[api_debug api_debug_web 26fb18404cb9d6afebc87349].each do |api_key|
        infos = Api::ApplicationKey.new(api_key: api_key).key_infos
        expect(infos).not_to have_key(:community)
      end
    end

    context 'Rails.env.test? and no api_key given' do
      before { Rails.env.stub(:test?) { true } }

      it 'falls back to the api_debug key infos' do
        fallback = Api::ApplicationKey.new(api_key: nil).key_infos
        expect(fallback).to eq(Api::ApplicationKey.new(api_key: 'api_debug').key_infos)
      end
    end
  end

  describe '#platform' do
    before { Rails.env.stub(:test?) { false } }

    it 'is :mobile for a mobile (iOS/Android) key' do
      expect(Api::ApplicationKey.new(api_key: 'api_debug').platform).to eq :mobile
    end

    it 'is :web for a web key' do
      expect(Api::ApplicationKey.new(api_key: 'api_debug_web').platform).to eq :web
    end

    it 'is nil for an unknown key' do
      expect(Api::ApplicationKey.new(api_key: 'foobar').platform).to be nil
    end
  end

  describe '.parse_platform_keys (env-var driven key/version parsing)' do
    let(:env_var) { 'APPLICATION_KEY_SPEC_TEST_KEYS' }

    around do |example|
      previous = ENV[env_var]
      example.run
      previous.nil? ? ENV.delete(env_var) : ENV[env_var] = previous
    end

    def parse(hmac_secret: 'shh')
      Api::ApplicationKey.send(
        :parse_platform_keys, env_var,
        device: 'iOS', device_family: UserApplication::IOS, hmac_secret: hmac_secret
      )
    end

    it 'parses each comma-separated "version:key" pair, keyed by the api key' do
      ENV[env_var] = '1.0.0:aaa,2.3.4:bbb'

      expect(parse).to eq(
        'aaa' => {version: '1.0.0', device: 'iOS', device_family: UserApplication::IOS},
        'bbb' => {version: '2.3.4', device: 'iOS', device_family: UserApplication::IOS},
      )
    end

    it 'returns an empty hash when the env var is unset' do
      ENV.delete(env_var)
      expect(parse).to eq({})
    end

    it 'returns an empty hash when the env var is blank' do
      ENV[env_var] = ''
      expect(parse).to eq({})
    end

    it 'omits hmac_secret for a version below HMAC_SINCE' do
      ENV[env_var] = '8.9.9:old'
      expect(parse['old']).not_to have_key(:hmac_secret)
    end

    it 'sets hmac_secret for a version at HMAC_SINCE' do
      ENV[env_var] = '9.0.0:atthreshold'
      expect(parse['atthreshold'][:hmac_secret]).to eq('shh')
    end

    it 'sets hmac_secret for a version above HMAC_SINCE, including across a digit-count change' do
      # regression test: Version used to compare "10" < "9" lexicographically
      ENV[env_var] = '10.0.0:newer'
      expect(parse['newer'][:hmac_secret]).to eq('shh')
    end
  end

  describe Api::ApplicationKey::Version do
    def v(string)
      described_class.new(string)
    end

    it 'compares numerically rather than lexicographically, against a raw version string' do
      expect(v('10.0.0') > '9.0.0').to be true
      expect(v('9.0.0') < '10.0.0').to be true
      expect(v('2.0.0') > '1.9.0').to be true
      expect(v('9.0.0') >= '9.0.0').to be true
    end

    it 'also compares directly against another Version instance' do
      expect(v('10.0.0')).to be > v('9.0.0')
      expect(v('9.0.0')).to be < v('10.0.0')
      expect(v('9.0.0')).to eq v('9.0.0')
    end

    it 'raises for a non-String version' do
      expect { v(9) }.to raise_error(ArgumentError, 'version must be a String')
    end
  end
end
