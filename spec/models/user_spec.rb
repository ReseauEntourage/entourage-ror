require 'rails_helper'

describe User, :type => :model do
  describe "public user" do
    it { expect(FactoryBot.build(:public_user, phone: nil).save).to be false }
    it { expect(FactoryBot.build(:public_user, sms_code: nil).save).to be false }
    it { expect(FactoryBot.build(:public_user, token: nil).save).to be false }
    it { expect(FactoryBot.build(:public_user, organization: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, first_name: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, last_name: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, email: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, device_type: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, device_id: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, validation_status: nil).save).to be false }
  end

  describe "pro user" do
    it { expect(FactoryBot.build(:pro_user, phone: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, sms_code: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, token: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, organization: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, first_name: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, last_name: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, email: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, device_type: nil).save).to be true }
    it { expect(FactoryBot.build(:pro_user, device_id: nil).save).to be true }
    it { expect(FactoryBot.build(:pro_user, device_id: nil).save).to be true }
    it { expect(FactoryBot.build(:public_user, validation_status: nil).save).to be false }
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

  describe "community" do
    let(:user) { create :public_user }
    it { should_not allow_value(nil).for(:community) }
    it { expect { user.community = ''; user.community }.to raise_error Community::NotFound }
    it { expect { user.community = ' '; user.community }.to raise_error Community::NotFound }
    it { expect { user.community = 'invalid'; user.community }.to raise_error Community::NotFound }
  end

  describe "phone number" do
    it { expect(FactoryBot.build(:pro_user, phone: '+33123456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '0123456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+33623456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '0623456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+33 6 23 45 67 89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06 23 45 67 89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06.23.45.67.89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+336.23.45.67.89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+336-23-45-67-89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06-23-45-67-89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '23-45-67-89').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+3323456789').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+33000000000').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+33600000000').save).to be true } #Apple account
    it { expect(FactoryBot.build(:pro_user, phone: '+32-2-555-12-12').save).to be true } #belgian number
    it { expect(FactoryBot.build(:pro_user, phone: '+1-999-999-9999').save).to be true } #canadian number
    it { expect(FactoryBot.build(:public_user, phone: '+40 (724) 593 579').save).to be true } #Apple formatted
  end

  describe "sms_code" do
    it { expect(FactoryBot.build(:pro_user, sms_code: '123456').save).to be true }
    it { expect(FactoryBot.build(:pro_user, sms_code: '12345').save).to be false }
    it { expect(FactoryBot.build(:pro_user, sms_code: '1234567').save).to be true }
  end

  it "validates uniqueness of token" do
    expect(FactoryBot.build(:pro_user, token: 'foo').save).to be true
    expect(FactoryBot.build(:pro_user, token: 'foo').save).to be false
  end

  it "doesn't validate uniqueness of email" do
    expect(FactoryBot.build(:pro_user, email: 'foo@bar.com').save).to be true
    expect(FactoryBot.build(:pro_user, email: 'foo@bar.com').save).to be true
    expect(FactoryBot.build(:public_user, email: 'foo@bar.com').save).to be true
    expect(FactoryBot.build(:public_user, email: 'foo@bar.com').save).to be true
  end

  it "validates uniqueness of phone" do
    expect(FactoryBot.build(:pro_user, token: '+33123456789').save).to be true
    expect(FactoryBot.build(:pro_user, token: '+33123456789').save).to be false
  end

  it "allows reuse of phone for different communities" do
    expect(FactoryBot.build(:public_user, phone: '+33123456789', community: 'entourage').save).to be true
    expect(FactoryBot.build(:public_user, phone: '+33123456789', community: 'pfp'      ).save).to be true
  end

  describe '#full_name' do
    subject { User.new(first_name: 'John', last_name: 'Doe').full_name }
    it { should eq 'John Doe' }
  end

  describe "organization association" do
    let(:valid_organization) { FactoryBot.build(:organization) }
    let(:invalid_organization) { FactoryBot.build(:organization, name: nil) }
    it { expect(FactoryBot.build(:pro_user, organization: nil).save).to be false }
    it { expect(FactoryBot.build(:pro_user, organization: invalid_organization).save).to be false }
    it { expect(FactoryBot.build(:pro_user, organization: valid_organization).save).to be true }
  end

  describe "set_phone" do
    it { expect(FactoryBot.create(:pro_user, phone: "0612345678").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "0112345678").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "01 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+331 12 34 56 78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "01.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+331.12.34.56.78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "01-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+331-12-34-56-78").phone).to eq('+33112345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+33612345678").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+32-2-555-12-12").phone).to eq('+3225551212') } #belgian number
    it { expect(FactoryBot.create(:pro_user, phone: "+1-999-999-9999").phone).to eq('+19999999999') } #canadian number

    context "updates with invalid phone number" do
      let(:user) { FactoryBot.create(:pro_user, phone: "+33612345678") }
      it { user.update(phone: "92345"); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: ""); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: "nil"); expect(user.reload.phone).to eq('+33612345678') }
    end
  end

  describe "password" do
    let(:user) { create(:public_user, password: "something") }

    def update params={}
      if user.update(params)
        user.previous_changes.key?('encrypted_password') ? :changed : :unchanged
      else
        user.errors.to_h
      end
    end

    it { expect(update updated_at: Time.now).to be :unchanged }
    it { expect(update password: nil).to be :unchanged }
    it { expect(update password: '').to eq password: "est trop court (au moins 8 caractères)" }
    it { expect(update password: ' ' * 10).to be :changed }
    it { expect(update password: 'x' * 10).to be :changed }
  end

  it "has many entourage_participations" do
    user = FactoryBot.create(:pro_user)
    entourage = FactoryBot.create(:entourage)
    create(:join_request, user: user, joinable: entourage)
    expect(user.entourage_participations).to eq([entourage])
  end

  it "has many tour_participations" do
    user = FactoryBot.create(:pro_user)
    tour = FactoryBot.create(:tour)
    create(:join_request, user: user, joinable: tour)
    expect(user.tour_participations).to eq([tour])
  end

  it "has many relations" do
    user1 = FactoryBot.create(:public_user)
    user2 = FactoryBot.create(:public_user)
    UserRelationship.create!(source_user: user1, target_user: user2, relation_type: UserRelationship::TYPE_INVITE )
    expect(user1.relations).to eq([user2])
  end

  it "has many invitations" do
    user = FactoryBot.create(:public_user)
    invitation = FactoryBot.create(:entourage_invitation, invitee: user)
    expect(user.invitations).to eq([invitation])
  end

  describe "apple?" do
    fr = Address.new(country: 'FR')
    us = Address.new(country: 'US')

    it { expect(FactoryBot.build(:public_user, id: 100, address: us).apple?).to be true }
    it { expect(FactoryBot.build(:public_user, id: 100, address: fr).apple?).to be false }
    it { expect(FactoryBot.build(:public_user, id: 101, address: us).apple?).to be true }
    it { expect(FactoryBot.build(:public_user, id: 101, address: fr).apple?).to be true }
  end

  def build_or_error *args
    o = build(*args)
    o.save || o.errors.to_h
  end

  describe 'roles' do
    it { expect(build_or_error :public_user, roles: [:moderator]).to eq(roles: ":moderator n'est pas inclus dans la liste") }
    it { expect(build_or_error :public_user, admin: true, roles: [:moderator]).to be true }
    it { expect(build_or_error :public_user, roles: [:lol]).to eq(roles: ":lol n'est pas inclus dans la liste") }
    it { expect(build_or_error :public_user, roles: [:ambassador]).to be true }
  end

  describe 'interests' do
    it { expect(build_or_error :public_user, interests: []).to be true }
    it { expect(build_or_error :public_user, interests: [:event_riverain, 'entourer_riverain']).to be true }
    it { expect(build_or_error :public_user, interests: [:aide_sdf, :lol]).to eq(interests: ":lol n'est pas inclus dans la liste") }
  end

  describe 'pending_phone_change_request' do
    let(:user) { FactoryBot.create(:pro_user, phone: '+33600000000', token: 'mytoken') }
    let(:admin) { FactoryBot.create(:admin_user, token: 'hertoken') }

    context 'user with no phone_change' do
      it { expect(user.pending_phone_change_request).to eq(nil) }
    end

    context 'user with a phone_change request' do
      let!(:phone_request) { FactoryBot.create(:user_phone_change_request, user_id: user.id, admin_id: admin.id) }
      it { expect(user.pending_phone_change_request.id).to eq(phone_request.id) }
    end
  end

  describe 'admin=' do
    context 'when false for a moderator' do
      let(:admin) { FactoryBot.create(:admin_user, roles: [:moderator]) }
      it { admin.update(admin: false); expect(admin.reload.admin).to eq(false) }
      it { admin.update(admin: false); expect(admin.reload.roles).to eq([]) }
      it { admin.update(admin: true); expect(admin.reload.admin).to eq(true) }
      it { admin.update(admin: true); expect(admin.reload.roles).to eq([:moderator]) }
    end

    context 'when false for a non-moderator' do
      let(:admin) { FactoryBot.create(:admin_user, roles: []) }
      it { admin.update(admin: false); expect(admin.reload.admin).to eq(false) }
      it { admin.update(admin: false); expect(admin.reload.roles).to eq([]) }
      it { admin.update(admin: true); expect(admin.reload.admin).to eq(true) }
      it { admin.update(admin: true); expect(admin.reload.roles).to eq([]) }
    end

    context 'when true' do
      let(:admin) { FactoryBot.create(:admin_user, admin: false, roles: []) }
      it { admin.update(admin: false); expect(admin.reload.admin).to eq(false) }
      it { admin.update(admin: false); expect(admin.reload.roles).to eq([]) }
      it { admin.update(admin: true); expect(admin.reload.admin).to eq(true) }
      it { admin.update(admin: true); expect(admin.reload.roles).to eq([]) }
    end
  end

  describe 'block_observer' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo') }
    let!(:open) { create(:entourage, user_id: user.id, status: :open) }
    let!(:suspended) { create(:entourage, user_id: user.id, status: :suspended) }

    let!(:other_user) { create(:public_user, phone: '+33600000010', token: 'bar', validation_status: :blocked) }
    let!(:other_entourage) { create(:entourage, user_id: other_user.id, status: :open) }

    context 'close entourages when user is blocked' do
      before { user.update(validation_status: :blocked) }

      it { expect(open.reload.status).to eq('closed') }
      it { expect(suspended.reload.status).to eq('suspended') }
      it { expect(other_entourage.reload.status).to eq('open') }
    end

    context 'close entourages when user is deleted' do
      before { user.update(deleted: true) }

      it { expect(open.reload.status).to eq('closed') }
      it { expect(suspended.reload.status).to eq('suspended') }
      it { expect(other_entourage.reload.status).to eq('open') }
    end

    context 'do not close entourages when user is back to validated' do
      before { user.update(validation_status: :validated) }

      it { expect(open.reload.status).to eq('open') }
      it { expect(suspended.reload.status).to eq('suspended') }
      it { expect(other_entourage.reload.status).to eq('open') }
    end
  end
end
