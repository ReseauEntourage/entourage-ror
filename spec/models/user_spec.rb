require 'rails_helper'

describe User, :type => :model do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:phone) }
  it { should validate_uniqueness_of(:email) }
  it { should define_enum_for(:device_type) }
  it { should allow_value('+33000000000').for(:phone) }
  it { should allow_value('+33123456789').for(:phone) }
  it { should allow_value('+33999999999').for(:phone) }
  it { should_not allow_value('01 23 45 67 89').for(:phone) }
  it { should_not allow_value('0123456789').for(:phone) }
  it { should_not allow_value('+3312345678').for(:phone) }
  it { should_not allow_value('+331234567890').for(:phone) }
  it { should_not allow_value('+33000a00000').for(:phone) }
  it { should allow_value('a@a.a').for(:email) }
  it { should_not allow_value('a-a.a').for(:email) }
  it { should_not allow_value('@').for(:email) }
  it { should have_many :tours }
  it { should have_many :encounters }
  
  context 'token automatically created' do
    let!(:user) { FactoryGirl.create :user, token: nil }
    it { expect(user.token.length).to eq(32) }
  end
  
  context 'sms_code automatically created' do
    let!(:user) { FactoryGirl.create :user, sms_code: nil }
    it { expect(user.sms_code.length).to be(6) }
  end
end