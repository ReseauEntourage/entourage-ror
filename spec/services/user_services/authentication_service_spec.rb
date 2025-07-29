require 'rails_helper'

describe UserServices::AuthenticationService do

  describe 'check_sms_code' do
    context 'valid user password' do
      before { ENV['DISABLE_CRYPT']='FALSE' }
      after { ENV['DISABLE_CRYPT']='TRUE' }
      let(:user) { FactoryBot.create(:pro_user, sms_code: 'foobar') }
      let(:password_service) { UserServices::AuthenticationService.new(user: user) }
      it { expect(password_service.check_sms_code('foobar')).to be true }
      it { expect(password_service.check_sms_code('toto')).to be false }
    end

    context 'invalid password' do
      it 'returns false' do
        user = FactoryBot.create(:pro_user)
        user.update_columns(sms_code: 'foobar')
        password_service = UserServices::AuthenticationService.new(user: user)
        expect(password_service.check_sms_code('toto')).to be false
      end
    end
  end

  describe 'check_password' do
    let(:password_service) { UserServices::AuthenticationService.new(user: user) }
    let(:user) { create :public_user, password: 'P@ssw0rd' }

    context 'valid user password' do
      it { expect(password_service.check_password('P@ssw0rd')).to be true }
      it { expect(password_service.check_password('Wr0ng123')).to be false }
    end

    context 'password not set' do
      before { user.update_columns(encrypted_password: nil) }
      it { expect(password_service.check_password('P@ssw0rd')).to be false }
    end

    context 'password is not a valid BCrypt hash' do
      before { user.update_columns(encrypted_password: 'P@ssw0rd') }
      it { expect(password_service.check_password('P@ssw0rd')).to be false }
    end
  end
end
