require 'rails_helper'

RSpec.describe UserApplication, type: :model do
  it { expect(FactoryBot.build(:user_application, device_family: UserApplication::IOS).save).to be true }
  it { should validate_presence_of :push_token }
  it { should validate_presence_of :device_os }
  it { should validate_presence_of :version }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :device_family }
  it { should validate_inclusion_of(:device_family).in_array([UserApplication::ANDROID, UserApplication::IOS, UserApplication::WEB]) }
  it { should belong_to :user }

  it 'can have multiple application version per user and device os' do
    user = FactoryBot.create(:pro_user)
    expect(FactoryBot.build(:user_application, user: user, device_family: UserApplication::IOS, version: '1.0').save).to be true
    expect(FactoryBot.build(:user_application, user: user, device_family: UserApplication::IOS, version: '1.0').save).to be true
    expect(FactoryBot.build(:user_application, user: user, device_family: UserApplication::ANDROID, version: '1.0').save).to be true
    expect(FactoryBot.build(:user_application, user: user, device_family: UserApplication::IOS, version: '1.1').save).to be true
  end

  it 'has unique push token' do
    expect(FactoryBot.build(:user_application, push_token: 'foo', device_family: UserApplication::IOS).save).to be true
    expect(FactoryBot.build(:user_application, push_token: 'foo', device_family: UserApplication::IOS).save).to be false
    expect(FactoryBot.build(:user_application, push_token: 'bar', device_family: UserApplication::IOS).save).to be true
  end

  describe 'skip_uniqueness_validation_of_push_token!' do
    let!(:existing) { create :user_application, push_token: 'foo', device_family: UserApplication::IOS }
    let(:duplicate) { build  :user_application, push_token: 'foo', device_family: UserApplication::IOS }

    context 'default' do
      it { expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid }
    end

    context 'skip validation' do
      before { duplicate.skip_uniqueness_validation_of_push_token! }
      it { expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique }
    end
  end
end
