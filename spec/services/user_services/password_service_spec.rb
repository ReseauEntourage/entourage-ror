require 'rails_helper'

describe UserServices::PasswordService do
  
  describe 'check_password' do
    context "valid user password" do
      before { ENV["DISABLE_CRYPT"]="FALSE" }
      after { ENV["DISABLE_CRYPT"]="TRUE" }
      let(:user) { FactoryGirl.create(:user, sms_code: "foobar") }
      let(:password_service) { UserServices::PasswordService.new(user: user) }
      it { expect(password_service.check_password("foobar")).to be true }
      it { expect(password_service.check_password("toto")).to be false }
    end

    context "invalid password" do
      it "returns false" do
        user = FactoryGirl.create(:user)
        user.update_columns(sms_code: "foobar")
        password_service = UserServices::PasswordService.new(user: user)
        expect(password_service.check_password("toto")).to be false
      end
    end
  end
end