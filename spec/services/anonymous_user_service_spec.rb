require 'rails_helper'

describe AnonymousUserService do
  let(:community) { $server_community }

  describe '.token?' do
    it 'recognizes a token it signed' do
      token = described_class.token_from_uuid(SecureRandom.uuid, community: community)

      expect(described_class.token?(token, community: community)).to eq true
    end

    [
      '',
      '1_anonymous_',
      '1_anonymous_abc',
      "1_anonymous_#{'a' * 36}",
      "1_anonymous_#{'a' * 36}_short",
      "1_anonymous_#{'a' * 36}_#{'b' * 40}"
    ].each do |malformed|
      it "answers false, without raising, for #{malformed.inspect}" do
        expect(described_class.token?(malformed, community: community)).to eq false
      end
    end

    it 'answers false for something that is not a string' do
      expect(described_class.token?(nil, community: community)).to eq false
    end
  end
end
