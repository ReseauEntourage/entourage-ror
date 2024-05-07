require 'rails_helper'

describe PartnerLogoUploader do
  # verify async method is reachable
  describe 'async' do
    let(:partner) { create :partner }

    before { described_class.stub(:authorized_params) }
    before { described_class.stub(:payload).and_return({ partner_id: partner.id, object_url: :url }) }

    after { described_class.handle_success(Hash.new)}

    it { expect(described_class).to receive(:delete_s3_object_with_public_url) }
  end
end
