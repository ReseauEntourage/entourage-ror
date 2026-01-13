require 'rails_helper'

describe SlackServices::PartnerUpdate do
  let(:user) { create(:public_user) }
  let(:partner) { create(:partner) }
  let(:partner_update) { described_class.new(user: user, partner: partner) }

  before { described_class.any_instance.stub(:changes).and_return({
    "description" => ['foo', 'bar'], "image_url" => ['jpeg', 'png' ]
  })}

  describe 'payload' do
    let(:subject) { partner_update.payload }

    it { expect(subject).to have_key(:text) }
    it { expect(subject).to have_key(:attachments) }
  end

  describe 'should notify' do
    let(:subject) { partner_update.send(:should_notify?) }

    context 'should notify' do
      before { described_class.any_instance.stub(:changes).and_return({
        "description" => ['foo', 'bar']
      })}

      it { expect(subject).to eq(true) }
    end

    context 'should not notify' do
      before { described_class.any_instance.stub(:changes).and_return({
        "email" => ['foo@bar.social', 'bar@foo.social']
      })}

      it { expect(subject).to eq(false) }
    end
  end
end
