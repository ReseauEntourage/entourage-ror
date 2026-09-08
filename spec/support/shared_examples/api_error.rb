# Shared example asserting the standard API error envelope produced by
# Api::V1::BaseController#render_error: a given HTTP status, plus a top-level
# `error: { code:, message: }` object. `code` is checked to always be a
# non-blank string since some mobile clients force-cast it and crash otherwise.
#
# Usage:
#   it_behaves_like "an api error", status: 403, code: "FORBIDDEN"
RSpec.shared_examples "an api error" do |status:, code:|
  let(:api_error_result) { JSON.parse(response.body) }

  it "returns a #{status} status" do
    expect(response.status).to eq(status)
  end

  it "returns error.code #{code.inspect}" do
    expect(api_error_result['error']['code']).to eq(code)
  end

  it 'returns a non-blank error.message' do
    expect(api_error_result['error']['message']).to be_a(String)
    expect(api_error_result['error']['message']).to_not be_blank
  end
end
