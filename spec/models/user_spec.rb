require 'rails_helper'

describe User, :type => :model do
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:phone) }
  it { should validate_uniqueness_of(:email) }
  it { should define_enum_for(:device_type) }
  
  context 'token automatically created' do
    let!(:user) { FactoryGirl.create :user, token: nil }
    it { expect(user.token.length).to eq(32) }
  end
  
  context 'sms_code automatically created' do
    let!(:user) { FactoryGirl.create :user, sms_code: nil }
    it { expect(user.sms_code.length).to be(6) }
  end
end