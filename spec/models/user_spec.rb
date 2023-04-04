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

  describe "birthday" do
    it { expect(FactoryBot.build(:pro_user, birthday: nil).save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '').save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '11').save).to be false }
    it { expect(FactoryBot.build(:pro_user, birthday: '1-1').save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '0-1').save).to be false }
    it { expect(FactoryBot.build(:pro_user, birthday: '01-1').save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '01-12').save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '01-13').save).to be false }
    it { expect(FactoryBot.build(:pro_user, birthday: '31-01').save).to be true }
    it { expect(FactoryBot.build(:pro_user, birthday: '31-02').save).to be false }
  end

  describe "phone number" do
    it { expect(FactoryBot.build(:pro_user, phone: '+33623456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '0623456789').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+33 6 23 45 67 89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06 23 45 67 89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06.23.45.67.89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+336.23.45.67.89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '+336-23-45-67-89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '06-23-45-67-89').save).to be true }
    it { expect(FactoryBot.build(:pro_user, phone: '').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+33600000000').save).to be true } #Apple account
    # only mobile
    it { expect(FactoryBot.build(:pro_user, phone: '+33123456789').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '0123456789').save).to be false }

    # foreign countries
    it { expect(FactoryBot.build(:pro_user, phone: '+32425551212').save).to be true } #belgian number as international (mobile)
    it { expect(FactoryBot.build(:pro_user, phone: '+32225551212').save).to be false } #belgian number as international (local)
    it { expect(FactoryBot.build(:pro_user, phone: '+1-999-999-9999').save).to be false } #canadian number
    it { expect(FactoryBot.build(:pro_user, phone: '+40 (724) 593 579').save).to be false } #Apple formatted
    # wrongs
    it { expect(FactoryBot.build(:pro_user, phone: '0425551212').save).to be false } #belgian number no international
    it { expect(FactoryBot.build(:pro_user, phone: '+33912345678').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '23-45-67-89').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+3323456789').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+33000000000').save).to be false }
    # using spamming numbers
    it { expect(FactoryBot.build(:pro_user, phone: '+923480000000').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+6282333333000').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+40768888800').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+529322222200').save).to be false }
    # starting with 06 but too long
    it { expect(FactoryBot.build(:pro_user, phone: '+336060606060616').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+336090909090919').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+336161616161616').save).to be false }
    it { expect(FactoryBot.build(:pro_user, phone: '+336191919191919').save).to be false }
  end

  describe "sms_code" do
    it { expect(FactoryBot.build(:pro_user, sms_code: '123456').save).to be true }
    it { expect(FactoryBot.build(:pro_user, sms_code: '12345').save).to be false }
    it { expect(FactoryBot.build(:pro_user, sms_code: '12345678901').save).to be true }
    it { expect(FactoryBot.build(:pro_user, sms_code: '1234567').save).to be true }
  end

  describe "sms_code_password" do
    it { expect(FactoryBot.build(:pro_user, sms_code_password: '123456').save).to be true }
    it { expect(FactoryBot.build(:pro_user, sms_code_password: '12345').save).to be false }
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
    expect(FactoryBot.build(:public_user, phone: '+33623456789', community: 'entourage').save).to be true
    expect(FactoryBot.build(:public_user, phone: '+33623456789', community: 'pfp'      ).save).to be true
  end

  describe 'status' do
    it { expect(User.new(validation_status: 'validated', deleted: false).status).to eq('validated') }
    it { expect(User.new(validation_status: 'validated', deleted: true).status).to eq('deleted') }
    it { expect(User.new(validation_status: 'blocked', deleted: true).status).to eq('deleted') }
    it { expect(User.new(validation_status: 'blocked', deleted: false).status).to eq('blocked') }
  end

  describe '#full_name' do
    subject { User.new(first_name: 'John', last_name: 'Doe').full_name }
    it { should eq 'John Doe' }
  end

  describe "search_by" do
    context "wrong search" do
      let!(:user) { FactoryBot.create(:pro_user, first_name: "Foo", last_name: "Bar") }
      it { expect(User.search_by("Foobar").pluck(:id)).to eq([]) }
    end

    context "without trailing spaces" do
      let!(:user) { FactoryBot.create(:pro_user, first_name: "Foo", last_name: "Bar") }
      it { expect(User.search_by("Foo Bar").pluck(:id)).to eq([user.id]) }
    end

    context "with trailing spaces" do
      let!(:user) { FactoryBot.create(:pro_user, first_name: "Foo ", last_name: "Bar ") }
      it { expect(User.search_by("Foo Bar").pluck(:id)).to eq([user.id]) }
    end

    context "without trailing spaces on first_name" do
      let!(:user) { FactoryBot.create(:pro_user, first_name: "Foo", last_name: "Bar") }
      it { expect(User.search_by("Foo").pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by("Foo ").pluck(:id)).to eq([user.id]) }
    end

    context "with trailing spaces on first_name" do
      let!(:user) { FactoryBot.create(:pro_user, first_name: "Foo ", last_name: "Bar ") }
      it { expect(User.search_by("Foo").pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by("Foo ").pluck(:id)).to eq([user.id]) }
    end
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
    it { expect(FactoryBot.create(:pro_user, phone: "06 12 34 56 78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+336 12 34 56 78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "06.12.34.56.78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+336.12.34.56.78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "06-12-34-56-78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+336-12-34-56-78").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+33612345678").phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:pro_user, phone: "+32455512121").phone).to eq('+32455512121') } #belgian number

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

  it "has many active followings" do
    user = FactoryBot.create(:public_user)
    following = FactoryBot.create(:following, user: user, active: true)
    expect(user.followings).to eq([following])
  end

  it "has many non active followings" do
    user = FactoryBot.create(:public_user)
    following = FactoryBot.create(:following, user: user, active: false)
    expect(user.followings).to eq([])
  end

  it "has many active subscriptions" do
    user = FactoryBot.create(:public_user)
    partner = FactoryBot.create(:partner)
    following = FactoryBot.create(:following, user: user, partner: partner, active: true)
    expect(user.subscriptions).to eq([partner])
  end

  it "has many non active subscriptions" do
    user = FactoryBot.create(:public_user)
    partner = FactoryBot.create(:partner)
    following = FactoryBot.create(:following, user: user, partner: partner, active: false)
    expect(user.subscriptions).to eq([])
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
    it { expect(build_or_error :public_user, interest_list: []).to be true }
    it { expect(build_or_error :public_user, interest_list: 'jeux').to be true }
    it { expect(build_or_error :public_user, interest_list: 'jeux, cuisine').to be true }
    it { expect(build_or_error :public_user, interest_list: 'culture, lol').to eq(interests: "lol n'est pas inclus dans la liste") }
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
    let!(:outing) { create(:outing, user_id: user.id, status: :open) }
    let!(:conversation) { create(:conversation, user_id: user.id, status: :open) }
    let!(:suspended) { create(:entourage, user_id: user.id, status: :suspended) }
    let!(:join_request_open) { create(:join_request, user: user, joinable: open, status: :accepted) }
    let!(:join_request_suspended) { create(:join_request, user: user, joinable: suspended, status: :accepted) }

    let!(:blocked_user) { create(:public_user, phone: '+33600000010', token: 'bar', validation_status: :blocked) }
    let!(:other_entourage) { create(:entourage, user_id: blocked_user.id, status: :open) }

    describe 'user is blocked' do
      context 'close entourages' do
        before { user.update(validation_status: :blocked) }

        it { expect(open.reload.status).to eq('closed') }
        it { expect(suspended.reload.status).to eq('suspended') }
        it { expect(other_entourage.reload.status).to eq('open') }
      end

      context 'a status_update message is requested' do
        before { expect_any_instance_of(ChatMessage).to receive(:status_update_content) }

        it { user.update(validation_status: :blocked) }
      end

      context 'a chat_message is created' do
        subject { user.update(validation_status: :blocked) }

        it { expect { subject }.to change { ChatMessage.count }.by 1 }
      end

      context 'the content of status_update message is specific' do
        before { user.update(validation_status: :blocked) }

        it {
          expect(ChatMessage.last.content).to eq(
            "a clôturé l’action : #{I18n.t("community.chat_messages.status_update.closed_user")}"
          )
        }
      end
    end

    describe 'user is deleted' do
      context 'close entourages' do
        before { user.update(deleted: true) }

        it { expect(open.reload.status).to eq('closed') }
        it { expect(suspended.reload.status).to eq('suspended') }
        it { expect(other_entourage.reload.status).to eq('open') }
      end

      context 'a status_update message is requested' do
        before { expect_any_instance_of(ChatMessage).to receive(:status_update_content) }

        it { user.update(deleted: true) }
      end

      context 'a chat_message is created' do
        subject { user.update(deleted: true) }

        it { expect { subject }.to change { ChatMessage.count }.by 1 }
      end

      context 'the content of status_update message is specific' do
        before { user.update(deleted: true) }

        it {
          expect(ChatMessage.last.content).to eq(
            "a clôturé l’action : #{I18n.t("community.chat_messages.status_update.closed_user")}"
          )
        }
      end
    end

    describe 'user is validated' do
      context 'do not send a message' do
        before {
          expect_any_instance_of(UserBlockObserver).to receive(:after_update)
          expect_any_instance_of(ChatMessage).not_to receive(:status_update_content)
        }

        it { blocked_user.update(validation_status: :validated) }
      end

      context 'do not close entourages' do
        before { blocked_user.update(validation_status: :validated) }

        it { expect(open.reload.status).to eq('open') }
        it { expect(suspended.reload.status).to eq('suspended') }
        it { expect(other_entourage.reload.status).to eq('open') }
      end
    end

    context 'close entourages when user is anonymized' do
      before { user.update(validation_status: :anonymized) }

      it { expect(open.reload.status).to eq('closed') }
      it { expect(suspended.reload.status).to eq('suspended') }
      it { expect(other_entourage.reload.status).to eq('open') }
    end

    context 'only entourages are closed when user is anonymized' do
      before {
        expect(EntouragesCloserJob).to receive(:perform_later).with([open.id], 'anonymized')
      }

      it { user.update(validation_status: :anonymized) }
    end
  end

  describe 'block!' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo') }
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    subject { user.block! moderator, 'explanation' }
    before { expect { subject }.to change { UserHistory.count }.by(1) }

    it { expect(UserHistory.last.kind).to eq('block') }
    it { expect(UserHistory.last.metadata[:temporary]).to eq(false) }
    it { expect(UserHistory.last.metadata[:cnil_explanation]).to eq('explanation') }
  end

  describe 'temporary_block!' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo') }
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    subject { user.temporary_block! moderator, 'explanation' }
    before { expect { subject }.to change { UserHistory.count }.by(1) }

    it { expect(UserHistory.last.kind).to eq('block') }
    it { expect(UserHistory.last.metadata[:temporary]).to eq(true) }
    it { expect(UserHistory.last.metadata[:cnil_explanation]).to eq('explanation') }
  end

  describe 'unblock!' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo') }
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    subject { user.unblock! moderator, 'explanation' }
    before { expect { subject }.to change { UserHistory.count }.by(1) }

    it { expect(UserHistory.last.kind).to eq('unblock') }
    it { expect(UserHistory.last.metadata[:temporary]).to be(nil) }
    it { expect(UserHistory.last.metadata[:cnil_explanation]).to eq('explanation') }
  end

  describe 'anonymize!' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo') }
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    subject { user.anonymize! moderator }
    before { expect { subject }.to change { UserHistory.count }.by(2) }

    it { expect(UserHistory.first.kind).to eq('anonymize') }
    it { expect(UserHistory.last.kind).to eq('deleted') }
    it { expect(UserHistory.last.metadata[:email_was]).to eq('anonymized') }
  end

  describe 'deleted' do
    let(:user) { create(:public_user, phone: '+33600000000', token: 'foo', email: 'foo@bar.com') }

    subject { user.update_attribute(:deleted, true) }
    before { expect { subject }.to change { UserHistory.count }.by(1) }

    it { expect(UserHistory.last.kind).to eq('deleted') }
    it { expect(UserHistory.last.metadata[:email_was]).to eq('foo@bar.com') }
  end
end
