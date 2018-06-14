require 'rails_helper'

RSpec.describe UserApplication, type: :model do
  it { expect(FactoryGirl.build(:user_application).save).to be true }
  it { should validate_presence_of :push_token }
  it { should validate_presence_of :device_os }
  it { should validate_presence_of :version }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :device_family }
  it { should validate_inclusion_of(:device_family).in_array([UserApplication::ANDROID, UserApplication::IOS, UserApplication::WEB]) }
  it { should belong_to :user }

  it "has unique application version per user and device os" do
    user = FactoryGirl.create(:pro_user)
    expect(FactoryGirl.build(:user_application, user: user, device_os: "ios", version: "1.0").save).to be true
    expect(FactoryGirl.build(:user_application, user: user, device_os: "ios", version: "1.0").save).to be false
    expect(FactoryGirl.build(:user_application, user: user, device_os: "android", version: "1.0").save).to be true
    expect(FactoryGirl.build(:user_application, user: user, device_os: "ios", version: "1.1").save).to be true
  end

  it "has unique push token" do
    expect(FactoryGirl.build(:user_application, push_token: "foo").save).to be true
    expect(FactoryGirl.build(:user_application, push_token: "foo").save).to be false
    expect(FactoryGirl.build(:user_application, push_token: "bar").save).to be true
  end
end
