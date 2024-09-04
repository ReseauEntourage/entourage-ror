require 'rails_helper'

RSpec.describe EntourageServices::Matcher do
  describe 'parse_matching' do
    let(:valid_json) do
      { "score" => 0.95, "type" => "action", "id" => "abc_uuid_v2" }
    end

    let(:invalid_json) { nil }

    it 'returns an empty array when json is nil' do
      expect(described_class.parse_matching(invalid_json)).to be_nil
    end

    it 'returns an empty array when json does not contain keys' do
      json_without_success = { "foo" => [] }
      expect(described_class.parse_matching(json_without_success)).to be_nil
    end

    it 'returns an empty array when json does not contain id key' do
      json_without_matchings = { "type" => "action" }
      expect(described_class.parse_matching(json_without_matchings)).to be_nil
    end

    it 'returns an empty array when json does not contain type key' do
      json_without_matchings = { "id" => "abc_uuid_v2" }
      expect(described_class.parse_matching(json_without_matchings)).to be_nil
    end

    it 'returns a list of matched objects when json is valid' do
      solicitation_double = double('Solicitation')
      
      expect(Action).to receive(:find_by_id_or_uuid).with('abc_uuid_v2').and_return(solicitation_double)

      result = described_class.parse_matching(valid_json)
      expect(result).to eq(solicitation_double)
    end
  end
end
