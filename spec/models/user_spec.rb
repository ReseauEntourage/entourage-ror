require 'rails_helper'

describe User, :type => :model do
  describe "public user" do
    it { expect(FactoryGirl.build(:public_user, phone: nil).save).to be false }
    it { expect(FactoryGirl.build(:public_user, sms_code: nil).save).to be false }
    it { expect(FactoryGirl.build(:public_user, token: nil).save).to be false }
    it { expect(FactoryGirl.build(:public_user, organization: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, first_name: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, last_name: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, email: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, device_type: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, device_id: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, validation_status: nil).save).to be false }
  end

  describe "pro user" do
    it { expect(FactoryGirl.build(:pro_user, phone: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, sms_code: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, token: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, organization: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, first_name: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, last_name: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, email: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, device_type: nil).save).to be true }
    it { expect(FactoryGirl.build(:pro_user, device_id: nil).save).to be true }
    it { expect(FactoryGirl.build(:pro_user, device_id: nil).save).to be true }
    it { expect(FactoryGirl.build(:public_user, validation_status: nil).save).to be false }
  end

  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:phone) }
  it { should validate_presence_of(:sms_code) }
  it { should validate_presence_of(:token) }
  it { should define_enum_for(:device_type) }
  it { should allow_value('a@a.a').for(:email) }
  it { should_not allow_value('a-a.a').for(:email) }
  it { should have_many :tours }
  it { should have_many :encounters }
  it { should have_many :entourages }
  it { should have_many :user_applications }
  it { should belong_to :organization }
  it { should have_and_belong_to_many(:coordinated_organizations).class_name('Organization') }

  describe "phone number" do
    it { expect(FactoryGirl.build(:pro_user, phone: '+33123456789').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '0123456789').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '+33623456789').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '0623456789').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '+33 6 23 45 67 89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '06 23 45 67 89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '06.23.45.67.89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '+336.23.45.67.89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '+336-23-45-67-89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '06-23-45-67-89').save).to be true }
    it { expect(FactoryGirl.build(:pro_user, phone: '').save).to be false }
    it { expect(FactoryGirl.build(:pro_user, phone: '23-45-67-89').save).to be false }
    it { expect(FactoryGirl.build(:pro_user, phone: '+3323456789').save).to be false }
    it { expect(FactoryGirl.build(:pro_user, phone: '+33000000000').save).to be false }
    it { expect(FactoryGirl.build(:pro_user, phone: '+33600000000').save).to be true } #Apple account
    it { expect(FactoryGirl.build(:pro_user, phone: '+32-2-555-12-12').save).to be true } #belgian number
    it { expect(FactoryGirl.build(:pro_user, phone: '+1-999-999-9999').save).to be true } #canadian number
  end

  it "validates uniqueness of token" do
    expect(FactoryGirl.build(:pro_user, token: 'foo').save).to be true
    expect(FactoryGirl.build(:pro_user, token: 'foo').save).to be false
  end

  it "validates uniqueness of email" do
    expect(FactoryGirl.build(:pro_user, email: 'foo@bar.com').save).to be true
    expect(FactoryGirl.build(:pro_user, email: 'foo@bar.com').save).to be false
  end

  it "validates uniqueness of phone" do
    expect(FactoryGirl.build(:pro_user, token: '+33123456789').save).to be true
    expect(FactoryGirl.build(:pro_user, token: '+33123456789').save).to be false
  end

  describe '#full_name' do
    subject { User.new(first_name: 'John', last_name: 'Doe').full_name }
    it { should eq 'John Doe' }
  end

  describe "organization association" do
    let(:valid_organization) { FactoryGirl.build(:organization) }
    let(:invalid_organization) { FactoryGirl.build(:organization, name: nil) }
    it { expect(FactoryGirl.build(:pro_user, organization: nil).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, organization: invalid_organization).save).to be false }
    it { expect(FactoryGirl.build(:pro_user, organization: valid_organization).save).to be true }
  end

  describe "set_phone" do
    it { expect(FactoryGirl.create(:pro_user, phone: "0612345678").phone).to eq('+33612345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "0112345678").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "01 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "+331 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "01.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "+331.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "01-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "+331-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "+33612345678").phone).to eq('+33612345678') }
    it { expect(FactoryGirl.create(:pro_user, phone: "+32-2-555-12-12").phone).to eq('+3225551212') } #belgian number
    it { expect(FactoryGirl.create(:pro_user, phone: "+1-999-999-9999").phone).to eq('+19999999999') } #canadian number

    context "updates with invalid phone number" do
      let(:user) { FactoryGirl.create(:pro_user, phone: "+33612345678") }
      it { user.update(phone: "92345"); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: ""); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: "nil"); expect(user.reload.phone).to eq('+33612345678') }
    end
  end

  it "has many entourage_participations" do
    user = FactoryGirl.create(:pro_user)
    entourage = FactoryGirl.create(:entourage)
    EntouragesUser.create(user: user, entourage: entourage)
    expect(user.entourage_participations).to eq([entourage])
  end

  it "has many tour_participations" do
    user = FactoryGirl.create(:pro_user)
    tour = FactoryGirl.create(:tour)
    ToursUser.create(user: user, tour: tour)
    expect(user.tour_participations).to eq([tour])
  end
end