require 'rails_helper'

describe User, :type => :model do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:phone) }
  it { should validate_presence_of(:sms_code) }
  it { should validate_presence_of(:token) }
  it { should validate_uniqueness_of(:token) }
  it { should validate_uniqueness_of(:email) }
  it { should define_enum_for(:device_type) }
  it { should validate_uniqueness_of(:phone) }
  it { expect(FactoryGirl.build(:user, phone: '+33123456789').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '0123456789').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '+33623456789').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '0623456789').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '+33 6 23 45 67 89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '06 23 45 67 89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '06.23.45.67.89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '+336.23.45.67.89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '+336-23-45-67-89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '06-23-45-67-89').save).to be true }
  it { expect(FactoryGirl.build(:user, phone: '').save).to be false }
  it { expect(FactoryGirl.build(:user, phone: '23-45-67-89').save).to be false }
  it { expect(FactoryGirl.build(:user, phone: '+3323456789').save).to be false }
  it { expect(FactoryGirl.build(:user, phone: '+33000000000').save).to be false }
  it { should allow_value('a@a.a').for(:email) }
  it { should_not allow_value('a-a.a').for(:email) }
  it { should have_many :tours }
  it { should have_many :encounters }
  it { should belong_to :organization }
  it { should validate_presence_of :organization }
  it { should have_and_belong_to_many(:coordinated_organizations).class_name('Organization') }

  describe '#full_name' do
    subject { User.new(first_name: 'John', last_name: 'Doe').full_name }
    it { should eq 'John Doe' }
  end

  describe "set_phone" do
    it { expect(FactoryGirl.create(:user, phone: "0612345678").phone).to eq('+33612345678') }
    it { expect(FactoryGirl.create(:user, phone: "0112345678").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "01 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "+331 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "01.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "+331.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "01-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "+331-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:user, phone: "+33612345678").phone).to eq('+33612345678') }

    context "updates with invalid phone number" do
      let(:user) { FactoryGirl.create(:user, phone: "+33612345678") }
      it { user.update(phone: "92345"); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: ""); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: "nil"); expect(user.reload.phone).to eq('+33612345678') }
    end
  end
end