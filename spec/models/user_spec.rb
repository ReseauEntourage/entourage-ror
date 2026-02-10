require 'rails_helper'

describe User, type: :model do
  describe 'public user' do
    it { expect(build(:public_user, phone: nil).save).to be false }
    it { expect(build(:public_user, sms_code: nil).save).to be false }
    it { expect(build(:public_user, token: nil).save).to be false }
    it { expect(build(:public_user).save).to be true }
    it { expect(build(:public_user, first_name: nil).save).to be true }
    it { expect(build(:public_user, last_name: nil).save).to be true }
    it { expect(build(:public_user, email: nil).save).to be true }
    it { expect(build(:public_user, device_type: nil).save).to be true }
    it { expect(build(:public_user, device_id: nil).save).to be true }
    it { expect(build(:public_user, validation_status: nil).save).to be false }
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
  it { should have_many :entourages }
  it { should have_many :user_applications }

  describe 'community' do
    let(:user) { create :public_user }
    it { should_not allow_value(nil).for(:community) }
    it { expect { user.community = ''; user.community }.to raise_error Community::NotFound }
    it { expect { user.community = ' '; user.community }.to raise_error Community::NotFound }
    it { expect { user.community = 'invalid'; user.community }.to raise_error Community::NotFound }
  end

  describe 'birthdate' do
    it { expect(build(:public_user, birthdate: nil).save).to be true }
    it { expect(build(:public_user, birthdate: '').save).to be true }
    it { expect(build(:public_user, birthdate: '11').save).to be false }
    it { expect(build(:public_user, birthdate: '1-1').save).to be false }
    it { expect(build(:public_user, birthdate: '2020-1-1').save).to be true }
    it { expect(build(:public_user, birthdate: '2020-1-0').save).to be false }
    it { expect(build(:public_user, birthdate: '2020-1-01').save).to be true }
    it { expect(build(:public_user, birthdate: '2020-12-01').save).to be true }
    it { expect(build(:public_user, birthdate: '2020-13-01').save).to be false }
    it { expect(build(:public_user, birthdate: '2020-01-31').save).to be true }
    it { expect(build(:public_user, birthdate: '2020-02-31').save).to be false }
  end

  describe 'phone number' do
    it { expect(build(:public_user, phone: '+33623456789').save).to be true }
    it { expect(build(:public_user, phone: '0623456789').save).to be true }
    it { expect(build(:public_user, phone: '+33 6 23 45 67 89').save).to be true }
    it { expect(build(:public_user, phone: '06 23 45 67 89').save).to be true }
    it { expect(build(:public_user, phone: '06.23.45.67.89').save).to be true }
    it { expect(build(:public_user, phone: '+336.23.45.67.89').save).to be true }
    it { expect(build(:public_user, phone: '+336-23-45-67-89').save).to be true }
    it { expect(build(:public_user, phone: '06-23-45-67-89').save).to be true }
    it { expect(build(:public_user, phone: '').save).to be false }
    it { expect(build(:public_user, phone: '+33600000000').save).to be true } #Apple account
    # only mobile
    it { expect(build(:public_user, phone: '+33123456789').save).to be false }
    it { expect(build(:public_user, phone: '0123456789').save).to be false }

    # foreign countries
    it { expect(build(:public_user, phone: '+32425551212').save).to be true } #belgian number as international (mobile)
    it { expect(build(:public_user, phone: '+32225551212').save).to be false } #belgian number as international (local)
    it { expect(build(:public_user, phone: '+1-999-999-9999').save).to be false } #canadian number
    it { expect(build(:public_user, phone: '+40 (724) 593 579').save).to be false } #Apple formatted
    # wrongs
    it { expect(build(:public_user, phone: '0425551212').save).to be false } #belgian number no international
    it { expect(build(:public_user, phone: '+33912345678').save).to be false }
    it { expect(build(:public_user, phone: '23-45-67-89').save).to be false }
    it { expect(build(:public_user, phone: '+3323456789').save).to be false }
    it { expect(build(:public_user, phone: '+33000000000').save).to be false }
    # using spamming numbers
    it { expect(build(:public_user, phone: '+923480000000').save).to be false }
    it { expect(build(:public_user, phone: '+6282333333000').save).to be false }
    it { expect(build(:public_user, phone: '+40768888800').save).to be false }
    it { expect(build(:public_user, phone: '+529322222200').save).to be false }
    # starting with 06 but too long
    it { expect(build(:public_user, phone: '+336060606060616').save).to be false }
    it { expect(build(:public_user, phone: '+336090909090919').save).to be false }
    it { expect(build(:public_user, phone: '+336161616161616').save).to be false }
    it { expect(build(:public_user, phone: '+336191919191919').save).to be false }
  end

  describe 'sms_code' do
    it { expect(build(:public_user, sms_code: '123456').save).to be true }
    it { expect(build(:public_user, sms_code: '12345').save).to be false }
    it { expect(build(:public_user, sms_code: '12345678901').save).to be true }
    it { expect(build(:public_user, sms_code: '1234567').save).to be true }
  end

  describe 'sms_code_password' do
    it { expect(build(:public_user, sms_code_password: '123456').save).to be true }
    it { expect(build(:public_user, sms_code_password: '12345').save).to be false }
  end

  describe 'gender=' do
    let(:user) { create(:public_user, gender: gender) }

    context "with invalid gender" do
      let(:gender) { "invalid" }
      it { expect { user }.to raise_error ActiveRecord::RecordInvalid }
    end

    context "with blank gender" do
      let(:gender) { "" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:gender]).to be_empty }
      it { expect(user.gender).to be_nil }
    end

    context "with nil gender" do
      let(:gender) { nil }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:gender]).to be_empty }
      it { expect(user.gender).to be_nil }
    end

    context "with valid gender" do
      let(:gender) { "secret" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:gender]).to be_empty }
      it { expect(user.gender).to eq("secret") }
    end
  end

  describe 'discovery_source=' do
    let(:user) { create(:public_user, discovery_source: discovery_source) }

    context "with invalid discovery_source" do
      let(:discovery_source) { "invalid" }
      it { expect { user }.to raise_error ActiveRecord::RecordInvalid }
    end

    context "with blank discovery_source" do
      let(:discovery_source) { "" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:discovery_source]).to be_empty }
      it { expect(user.discovery_source).to be_nil }
    end

    context "with nil discovery_source" do
      let(:discovery_source) { nil }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:discovery_source]).to be_empty }
      it { expect(user.discovery_source).to be_nil }
    end

    context "with valid discovery_source" do
      let(:discovery_source) { "television" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:discovery_source]).to be_empty }
      it { expect(user.discovery_source).to eq("television") }
    end
  end

  describe 'sf_entreprise_id=' do
    let(:user) { create(:public_user, sf_entreprise_id: sf_entreprise_id) }

    context "with invalid sf_entreprise_id" do
      let(:sf_entreprise_id) { "invalid" }
      it { expect { user }.to raise_error ActiveRecord::RecordInvalid }
    end

    context "with blank sf_entreprise_id" do
      let(:sf_entreprise_id) { "" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_entreprise_id]).to be_empty }
      it { expect(user.sf_entreprise_id).to be_nil }
    end

    context "with nil sf_entreprise_id" do
      let(:sf_entreprise_id) { nil }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_entreprise_id]).to be_empty }
      it { expect(user.sf_entreprise_id).to be_nil }
    end

    context "with valid sf_entreprise_id" do
      let(:sf_entreprise_id) { "0123456789ABCdeFGH" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_entreprise_id]).to be_empty }
      it { expect(user.sf_entreprise_id).to eq("0123456789ABCdeFGH") }
    end
  end

  describe 'sf_campaign_id=' do
    let(:user) { create(:public_user, sf_campaign_id: sf_campaign_id) }

    before { User.any_instance.stub(:sync_sf_entreprise_participant_async) }

    context "with invalid sf_campaign_id" do
      let(:sf_campaign_id) { "invalid" }
      it { expect { user }.to raise_error ActiveRecord::RecordInvalid }
    end

    context "with blank sf_campaign_id" do
      let(:sf_campaign_id) { "" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_campaign_id]).to be_empty }
      it { expect(user.sf_campaign_id).to be_nil }
    end

    context "with nil sf_campaign_id" do
      let(:sf_campaign_id) { nil }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_campaign_id]).to be_empty }
      it { expect(user.sf_campaign_id).to be_nil }
    end

    context "with valid sf_campaign_id" do
      let(:sf_campaign_id) { "0123456789ABCdeFGH" }
      it { expect { user }.not_to raise_error }
      it { expect(user.errors[:sf_campaign_id]).to be_empty }
      it { expect(user.sf_campaign_id).to eq("0123456789ABCdeFGH") }
    end
  end

  describe 'goal=' do
    it { expect(build(:public_user, goal: 'offer_help').goal_choice).to eq('offer_help') }
    it { expect(build(:public_user, goal: 'offer_help').goal).to eq('offer_help') }

    it { expect(build(:public_user, goal: 'ask_for_help').goal_choice).to eq('ask_for_help') }
    it { expect(build(:public_user, goal: 'ask_for_help').goal).to eq('ask_for_help') }

    it { expect(build(:public_user, goal: 'ask_and_offer_help').goal_choice).to eq('ask_and_offer_help') }
    it { expect(build(:public_user, goal: 'ask_and_offer_help').goal).to eq('ask_for_help') }
  end

  it 'validates uniqueness of token' do
    expect(build(:public_user, token: 'foo').save).to be true
    expect(build(:public_user, token: 'foo').save).to be false
  end

  it "doesn't validate uniqueness of email" do
    expect(build(:public_user, email: 'foo@bar.com').save).to be true
    expect(build(:public_user, email: 'foo@bar.com').save).to be true
  end

  it 'validates uniqueness of phone' do
    expect(build(:public_user, token: '+33123456789').save).to be true
    expect(build(:public_user, token: '+33123456789').save).to be false
  end

  it 'allows reuse of phone for different communities' do
    expect(build(:public_user, phone: '+33623456789', community: 'entourage').save).to be true
    expect(build(:public_user, phone: '+33623456789', community: 'pfp'      ).save).to be true
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

  describe 'search_by' do
    context 'wrong search' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Foo', last_name: 'Bar') }
      it { expect(User.search_by('Foobar').pluck(:id)).to eq([]) }
      it { expect(User.search_by('Fooo').pluck(:id)).to eq([]) }
    end

    context 'without trailing spaces' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Foo', last_name: 'Bar') }
      it { expect(User.search_by('Foo Bar').pluck(:id)).to eq([user.id]) }
    end

    context 'with trailing spaces' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Foo', last_name: 'Bar') }
      it { expect(User.search_by('  Foo Bar  ').pluck(:id)).to eq([user.id]) }
    end

    context 'without trailing spaces on first_name' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Foo', last_name: 'Bar') }
      it { expect(User.search_by('Foo').pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by('Foo ').pluck(:id)).to eq([user.id]) }
    end

    context 'with accent' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Féo', last_name: 'Barè') }
      it { expect(User.search_by('Feo').pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by('Bare ').pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by('Fare ').pluck(:id)).to eq([]) }
    end

    context 'with reversed accent' do
      let!(:user) { FactoryBot.create(:public_user, first_name: 'Feo', last_name: 'Bare') }
      it { expect(User.search_by('Féo').pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by('Barè ').pluck(:id)).to eq([user.id]) }
      it { expect(User.search_by('Farè ').pluck(:id)).to eq([]) }
    end
  end

  describe 'set_phone' do
    it { expect(FactoryBot.create(:public_user, phone: '0612345678').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '06 12 34 56 78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '+336 12 34 56 78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '06.12.34.56.78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '+336.12.34.56.78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '06-12-34-56-78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '+336-12-34-56-78').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '+33612345678').phone).to eq('+33612345678') }
    it { expect(FactoryBot.create(:public_user, phone: '+32455512121').phone).to eq('+32455512121') } #belgian number

    context 'updates with invalid phone number' do
      let(:user) { FactoryBot.create(:public_user, phone: '+33612345678') }
      it { user.update(phone: '92345'); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: ''); expect(user.reload.phone).to eq('+33612345678') }
      it { user.update(phone: 'nil'); expect(user.reload.phone).to eq('+33612345678') }
    end
  end

  describe 'password' do
    let(:user) { create(:public_user, password: 'something') }

    def update params={}
      if user.update(params)
        user.previous_changes.key?('encrypted_password') ? :changed : :unchanged
      else
        user.errors.to_hash
      end
    end

    it { expect(update updated_at: Time.now).to be :unchanged }
    it { expect(update password: nil).to be :unchanged }
    it { expect(update password: '').to eq password: ['est trop court (au moins 8 caractères)'] }
    it { expect(update password: ' ' * 10).to be :changed }
    it { expect(update password: 'x' * 10).to be :changed }
  end

  it 'has many entourage_participations' do
    user = FactoryBot.create(:public_user)
    entourage = FactoryBot.create(:entourage)
    create(:join_request, user: user, joinable: entourage)
    expect(user.entourage_participations).to eq([entourage])
  end

  it 'has many relations' do
    user1 = FactoryBot.create(:public_user)
    user2 = FactoryBot.create(:public_user)
    UserRelationship.create!(source_user: user1, target_user: user2, relation_type: UserRelationship::TYPE_INVITE )
    expect(user1.relations).to eq([user2])
  end

  it 'has many invitations' do
    user = FactoryBot.create(:public_user)
    invitation = FactoryBot.create(:entourage_invitation, invitee: user)
    expect(user.invitations).to eq([invitation])
  end

  it 'has many active followings' do
    user = FactoryBot.create(:public_user)
    following = FactoryBot.create(:following, user: user, active: true)
    expect(user.followings).to eq([following])
  end

  it 'has many non active followings' do
    user = FactoryBot.create(:public_user)
    following = FactoryBot.create(:following, user: user, active: false)
    expect(user.followings).to eq([])
  end

  it 'has many active subscriptions' do
    user = FactoryBot.create(:public_user)
    partner = FactoryBot.create(:partner)
    following = FactoryBot.create(:following, user: user, partner: partner, active: true)
    expect(user.subscriptions).to eq([partner])
  end

  it 'has many non active subscriptions' do
    user = FactoryBot.create(:public_user)
    partner = FactoryBot.create(:partner)
    following = FactoryBot.create(:following, user: user, partner: partner, active: false)
    expect(user.subscriptions).to eq([])
  end

  def build_or_error *args
    o = build(*args)
    o.save || o.errors.to_hash
  end

  describe 'roles' do
    it { expect(build_or_error :public_user, roles: [:moderator]).to eq(roles: [":moderator n'est pas inclus dans la liste"]) }
    it { expect(build_or_error :public_user, admin: true, roles: [:moderator]).to be true }
    it { expect(build_or_error :public_user, roles: [:lol]).to eq(roles: [":lol n'est pas inclus dans la liste"]) }
    it { expect(build_or_error :public_user, roles: [:ambassador]).to be true }
  end

  describe 'interests' do
    it { expect(build_or_error :public_user, interest_list: []).to be true }
    it { expect(build_or_error :public_user, interest_list: 'jeux').to be true }
    it { expect(build_or_error :public_user, interest_list: 'jeux, cuisine').to be true }
    it { expect(build_or_error :public_user, interest_list: 'culture, lol').to eq(interests: ["lol n'est pas inclus dans la liste"]) }
  end

  describe 'pending_phone_change_request' do
    let(:user) { FactoryBot.create(:public_user, phone: '+33600000000', token: 'mytoken') }
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
    end

    describe 'user is deleted' do
      context 'close entourages' do
        before { user.update(deleted: true) }

        it { expect(open.reload.status).to eq('closed') }
        it { expect(suspended.reload.status).to eq('suspended') }
        it { expect(other_entourage.reload.status).to eq('open') }
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

  describe 'availability' do
    let(:availability) { Hash.new }
    subject { build(:public_user, availability: availability) }

    context 'is valid with valid availability' do
      let(:availability) {{
        '1' => ['09:00-12:00', '14:00-18:00'],
        '2' => ['10:00-12:00']
      }}

      it { should be_valid }
    end

    context 'is not valid with an invalid availability day' do
      let(:availability) {{
        '8' => ['09:00-12:00'] # Jour invalide (devrait être entre 1 et 7)
      }}

      it { should_not be_valid }
    end

    context 'is not valid with an invalid availability format' do
      let(:availability) {{
        '1' => ['09:00-25:00'] # Format d'heure invalide
      }}

      it { should_not be_valid }
    end

    context 'is not valid with an invalid availability format' do
      let(:availability) { 'invalid data' }

      it { should_not be_valid }
    end
  end

  describe '#birthday_today?' do
    subject(:birthday_today?) { user.birthday_today? }

    let(:user) { build(:user, birthdate: birthdate) }

    context 'when birthdate is nil' do
      let(:birthdate) { nil }

      it { is_expected.to be false }
    end

    context 'when today is the birthday' do
      let(:birthdate) { "1990/01/26" }

      before { Timecop.freeze(Time.zone.local(2026, 1, 26)) }

      it { is_expected.to be true }
    end

    context 'when today is not the birthday' do
      let(:birthdate) { "1990/01/26" }

      before { Timecop.freeze(Time.zone.local(2026, 1, 27)) }

      it { is_expected.to be false }
    end

    context 'when born on february 29' do
      let(:birthdate) { "2004/02/29" }

      context 'on a non-leap year, february 28' do
        # non bissextile
        before { Timecop.freeze(Time.zone.local(2025, 2, 28)) }

        it { is_expected.to be true }
      end

      context 'on a non-leap year, march 1' do
        before { Timecop.freeze(Time.zone.local(2025, 3, 1)) }

        it { is_expected.to be false }
      end

      context 'on a leap year, february 29' do
        # bissextile
        before { Timecop.freeze(Time.zone.local(2024, 2, 29)) }

        it { is_expected.to be true }
      end
    end
  end
end
