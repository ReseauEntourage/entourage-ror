require 'rails_helper'
include CommunityHelper

RSpec.describe Entourage, type: :model do
  it { expect(FactoryBot.build(:entourage).save!).to be true }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:entourage_type) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_presence_of(:number_of_people) }
  it { should validate_inclusion_of(:status).in_array(["open", "closed", "blacklisted", "suspended"]) }
  it { should validate_inclusion_of(:entourage_type).in_array(["ask_for_help", "contribution"]) }
  it { should validate_inclusion_of(:category).in_array(['mat_help', 'non_mat_help', 'social']) }
  it { should belong_to(:user) }

  describe "validate_inclusion_of status" do
    context 'is an event' do
      before { allow(subject).to receive(:outing?).and_return(true) }
      it { is_expected.to validate_inclusion_of(:status).in_array(["open", "closed", "blacklisted", "suspended", "full", "cancelled"]) }
    end

    context 'is not an event' do
      before { allow(subject).to receive(:outing?).and_return(false) }
      it { is_expected.to validate_inclusion_of(:status).in_array(["open", "closed", "blacklisted", "suspended"]) }
    end
  end

  describe "group_type" do
    it { expect(build(:entourage, group_type: :invalid).save).to eq false }
    it { expect(build(:entourage, group_type: :action).save).to eq true }
  end

  describe "reformat_content" do
    it "should uppercase first character" do
      entourage = FactoryBot.create(:entourage, title: 'title')
      entourage.save
      expect(entourage.title).to eq('Title')
    end
    it "should uppercase only first character" do
      entourage = FactoryBot.create(:entourage, title: 'title FOO Bar')
      entourage.save
      expect(entourage.title).to eq('Title FOO Bar')
    end
    it "should not uppercase first character on emoji" do
      entourage = FactoryBot.create(:entourage, title: '👌title')
      entourage.save
      expect(entourage.title).to eq('👌title')
    end
  end

  it "has many members" do
    user = FactoryBot.create(:public_user)
    entourage = FactoryBot.create(:entourage)
    FactoryBot.create(:join_request, user: user, joinable: entourage)
    expect(entourage.members).to eq([user])
  end

  it "has many chat messages" do
    entourage = FactoryBot.create(:entourage)
    chat_message = FactoryBot.create(:chat_message, messageable: entourage)
    expect(entourage.chat_messages).to eq([chat_message])
  end

  describe 'moderate after create' do
    it 'should not ping Slack if description is acceptable' do
      entourage = FactoryBot.create(:entourage, description: 'Coucou, je veux donner des jouets.')
      expect(entourage).not_to receive(:ping_slack)
    end

    it 'should ping Slack if description is unacceptable' do
      entourage = FactoryBot.build(
        :entourage,
        description: 'Hello, je veux donner des jouets au 9 rue Marcel Sembat.'
      )

      stub_request(:any, "https://hooks.slack.com").to_return(body: "abc", status: 200)
      entourage.should_receive :ping_slack
      entourage.save
    end
  end

  describe "metadata" do
    let(:now) { Time.now.change(sec: 42) }
    let!(:outing) { create(:outing, metadata: {starts_at: now}).reload }

    it { expect(Entourage.where("metadata->>'starts_at' < ?", now + 1).pluck(:id)).to eq [outing.id] }
    it { expect(Entourage.where("metadata->>'starts_at' > ?", now - 1).pluck(:id)).to eq [outing.id] }
    it { expect(Entourage.where("metadata->>'starts_at' = ?", now    ).pluck(:id)).to eq [outing.id] }
    it { expect(Entourage.where("metadata->>'starts_at' between ? and ?", now - 1, now + 1).pluck(:id)).to eq [outing.id] }

    it { expect(outing.metadata[:starts_at]).to be_a ActiveSupport::TimeWithZone }
    it { expect(outing.metadata[:starts_at].time_zone.name).to eq(Time.zone.name) }

    it { expect(outing.metadata).to eq(
      starts_at: now,
      ends_at: now + 3.hours,
      previous_at: nil,
      display_address: "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris",
      place_name: "Café la Renaissance",
      street_address: "44 rue de l’Assomption, 75016 Paris, France",
      google_place_id: "foobar",
      landscape_url: nil,
      landscape_thumbnail_url: nil,
      portrait_url: nil,
      portrait_thumbnail_url: nil,
      place_limit: nil,
      :$id=>"urn:entourage:outing:metadata"
    ) }
    it { expect(build(:outing, default_metadata: {}).tap(&:save).errors.messages).to eq(
      metadata: ["did not contain a required property of 'starts_at'",
                 "did not contain a required property of 'ends_at'",
                 "did not contain a required property of 'place_name'",
                 "did not contain a required property of 'street_address'",
                 "did not contain a required property of 'google_place_id'"]
    ) }
    it { expect(build(:outing, metadata: {starts_at: "lol", street_address: 42}).tap(&:save).errors.messages).to eq(
      metadata: ["'starts_at' must be a valid ISO 8601 date/time string",
                 "'street_address' of type integer did not match the following type: string",
                 "did not contain a required property of 'ends_at'"]
    ) }
    it { expect(build(:outing, metadata: {starts_at: now, ends_at: now-1}).tap(&:save).errors.messages).to eq(
      metadata: ["'ends_at' must not be before 'starts_at'"]
    ) }
  end

  describe "format_metadata_image_paths" do
    let(:now) { Time.now.change(sec: 42) }
    let!(:outing) { create(:outing, metadata: {
      starts_at: now,
      landscape_url: 'https://myserver.com/entourage_images/images/mypicture.png?X-Amz-Algorithm=AWS4-HMAC-SHA256',
      landscape_thumbnail_url: 'http://myserver.com/entourage_images/images/mypicture.png?X-Amz-Algorithm=AWS4-HMAC-SHA256',
      portrait_url: 'http://myserver.com/entourage_images/images/mypicture.png',
      portrait_thumbnail_url: 'entourage_images/images/mypicture.png',
    }) }

    it { expect(outing.metadata[:landscape_url]).to eq('entourage_images/images/mypicture.png') }
    it { expect(outing.metadata[:landscape_thumbnail_url]).to eq('entourage_images/images/mypicture.png') }
    it { expect(outing.metadata[:portrait_url]).to eq('entourage_images/images/mypicture.png') }
    it { expect(outing.metadata[:portrait_thumbnail_url]).to eq('entourage_images/images/mypicture.png') }
  end

  describe "public accessibility" do
    it { expect(build(:entourage, group_type: :conversation, public: true).tap(&:save).errors.messages).to eq(
      public: ["n'est pas inclus(e) dans la liste"]
    ) }
  end

  it "has an uuid" do
    entourage = FactoryBot.create(:entourage)

    expect(entourage.uuid).to_not be nil
  end

  describe "has a v2 uuid" do
    let(:entourage) { create :entourage }

    describe "format" do
      it { expect(entourage.uuid_v2[0]).to eq 'e' }
      it { expect(entourage.uuid_v2.length).to eq 12 }
    end

    describe "retries automatically if not unique" do
      let(:new_entourage) { build :entourage }
      let(:existing_uuid_v2) { entourage.uuid_v2 }
      let(:new_uuid_v2) { Entourage.generate_uuid_v2 }
      before {
        allow(Entourage).to receive(:generate_uuid_v2).and_return(
          existing_uuid_v2,
          new_uuid_v2
        )
        new_entourage.save
      }

      it { expect(new_entourage.uuid_v2).to eq new_uuid_v2 }
      it { expect(Entourage).to have_received(:generate_uuid_v2).exactly(2).times }
      it { expect(Entourage.count).to eq 2 }
    end
  end

  describe '.findable_by_id_or_uuid' do
    subject { Entourage.findable_by_id_or_uuid identifier }

    context "when the entourage exists" do
      let(:entourage) { create :entourage }

      context "when searching with an integer id" do
        let(:identifier) { entourage.id }
        it { is_expected.to eq entourage }
      end

      context "when searching with an string id" do
        let(:identifier) { entourage.id.to_s }
        it { is_expected.to eq entourage }
      end

      context "when searching with a v1 uuid" do
        let(:identifier) { entourage.uuid }
        it { is_expected.to eq entourage }
      end

      context "when searching with a v2 uuid" do
        let(:identifier) { entourage.uuid_v2 }
        it { is_expected.to eq entourage }
      end
    end

    context "when the entourage doesn't exists" do
      context "when searching with an integer id" do
        let(:identifier) { 1234 }
        it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with an string id" do
        let(:identifier) { "1234" }
        it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with a v1 uuid" do
        let(:identifier) { "59f213f2-7101-4c4c-b9a2-e298d9cb56af" }
        it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with a v2 uuid" do
        let(:identifier) { "emRCdKR0VOio" }
        it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
      end
    end
  end

  describe 'updated_at' do
    let!(:group) { create :entourage, updated_at: 1.hour.ago }

    shared_examples "is updated" do
      it "is updated" do
        expect { subject }.to change { group.reload.updated_at }
      end
    end

    shared_examples "is not updated" do
      it "is not updated" do
        expect { subject }.not_to change { group.reload.updated_at }
      end
    end

    describe "on new pending join requests" do
      subject { create :join_request, status: :pending, joinable: group }
      include_examples "is updated"
    end

    describe "when an existing join request is made pending again" do
      let!(:join_request) { create :join_request, status: :cancelled, joinable: group }
      subject { join_request.update(status: :pending) }
      include_examples "is updated"
    end

    describe "on new chat_messages" do
      subject { create :chat_message, messageable: group }
      include_examples "is updated"
    end

    describe "on new chat_message of type status_update" do
      subject { create :chat_message, :closed_as_success, messageable: group }
      include_examples "is not updated"
    end
  end

  describe 'feed_updated_at' do
    let!(:group) { create :entourage, updated_at: 1.hour.ago }

    shared_examples "is updated" do
      it "is updated" do
        expect { subject }.to change { group.reload.feed_updated_at }
      end
    end

    shared_examples "is not updated" do
      it "is not updated" do
        expect { subject }.not_to change { group.reload.feed_updated_at }
      end
    end

    describe "on new pending join requests" do
      subject { create :join_request, status: :pending, joinable: group }
      include_examples "is updated"
    end

    describe "when an existing join request is made pending again" do
      let!(:join_request) { create :join_request, status: :cancelled, joinable: group }
      subject { join_request.update(status: :pending) }
      include_examples "is updated"
    end

    describe "on new chat_messages" do
      subject { create :chat_message, messageable: group }
      include_examples "is updated"
    end

    describe "on new chat_message of type status_update" do
      subject { create :chat_message, :closed_as_success, messageable: group }
      include_examples "is not updated"
    end
  end

  describe "no_moderator_read_for" do
    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) { FactoryBot.create(:entourage) }

    it "moderator has no read" do
      expect(entourage.no_moderator_read_for(user: user)).to eq(true)
    end

    it "moderator has reads" do
      moderator_read = FactoryBot.create(:moderator_read, moderatable: entourage, user: user)

      expect(entourage.no_moderator_read_for(user: user)).to eq(false)
    end
  end

  describe "unread_chat_message_after" do
    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) {FactoryBot.create(:entourage) }
    let(:at) { Time.now }

    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: entourage) }

    it "no unread_chat_message after" do
      expect(entourage.unread_chat_message_after(read_at: at + 1.second)).to eq(false)
    end

    it "with unread_chat_message after" do
      expect(entourage.unread_chat_message_after(read_at: at - 1.second)).to eq(true)
    end
  end

  describe "moderator_has_unread_content" do
    let(:user) { FactoryBot.create(:public_user) }
    let(:entourage) {FactoryBot.create(:entourage) }
    let(:at) { Time.now }

    let!(:join_request) { FactoryBot.create(:join_request, user: user, joinable: entourage, status: JoinRequest::ACCEPTED_STATUS, created_at: at) }
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: entourage) }

    it "no unread_content" do
      expect(entourage.moderator_has_unread_content(user: user)).to eq(true)
    end

    it "with unread_content" do
      moderator_read = FactoryBot.create(:moderator_read, moderatable: entourage, user: user)
      expect(entourage.moderator_has_unread_content(user: user)).to eq(false)
    end
  end

  describe "status_changed_at" do
    let(:entourage) { FactoryBot.create(:entourage, status: :open) }

    context 'set status_changed_at' do
      before { entourage.update(status: :closed) }

      it { expect(entourage.status).to eq("closed") }
      it { expect(entourage.status_changed_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end
end
