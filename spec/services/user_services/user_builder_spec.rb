require 'rails_helper'

describe UserServices::ProUserBuilder do
  describe 'create' do
    before { UserServices::SmsCode.any_instance.stub(:code) { "123456" }}
    let(:params) do FactoryBot.build(:user).attributes.select {|k, v| ["email", "first_name", "last_name", "phone"].include?(k) }.with_indifferent_access end
    let(:organization) { FactoryBot.build(:organization) }

    it 'sends sms with created code' do
      expect_any_instance_of(UserServices::SmsSender).to receive(:send_welcome_sms).with("123456").once
      UserServices::ProUserBuilder.new(params: params, organization: organization).create(send_sms: true)
    end

    it "doesn't send sms with created code" do
      expect_any_instance_of(UserServices::SmsSender).to receive(:send_welcome_sms).never
      UserServices::ProUserBuilder.new(params: params, organization: organization).create(send_sms: false)
    end
  end

  describe 'update' do
    let(:organization) { FactoryBot.create(:organization) }
    let!(:user) { FactoryBot.create(:user, organization_id: organization.id) }
    let!(:blocked) { FactoryBot.create(:user, validation_status: :blocked, email: 'blocked@email.fr', organization_id: organization.id) }

    before {
      allow_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify).and_return(nil)
    }

    context 'no update to email should not send a signal' do
      it {
        UserServices::PublicUserBuilder.new(params: { email: user.email }, community: nil).update(user: user)
        expect_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify).never
      }
    end

    context 'update to non-blocked email should not send a signal' do
      it {
        expect_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify).never
        UserServices::PublicUserBuilder.new(params: { email: 'new@email.fr' }, community: nil).update(user: user)
      }
    end

    context 'update to blocked email should send a signal' do
      it {
        expect_any_instance_of(SlackServices::SignalUserCreation).to receive(:notify)
        UserServices::PublicUserBuilder.new(params: { email: 'blocked@email.fr' }, community: nil).update(user: user)
      }
    end
  end
end
