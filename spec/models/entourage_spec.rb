require 'rails_helper'
include CommunityHelper

RSpec.describe Entourage, type: :model do
  it { expect(FactoryGirl.build(:entourage).save!).to be true }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:entourage_type) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_presence_of(:number_of_people) }
  it { should validate_inclusion_of(:status).in_array(["open", "closed"]) }
  it { should validate_inclusion_of(:entourage_type).in_array(["ask_for_help", "contribution"]) }
  it { should validate_inclusion_of(:category).in_array(['mat_help', 'non_mat_help', 'social']) }
  it { should belong_to(:user) }

  describe "group_type" do
    it { expect(build(:entourage, group_type: :invalid).save).to eq false }
    it { expect(build(:entourage, group_type: :action).save).to eq true }
    it { expect(build(:entourage, community: :pfp, group_type: :private_circle).save).to eq true }
  end

  it "has many members" do
    user = FactoryGirl.create(:public_user)
    entourage = FactoryGirl.create(:entourage)
    FactoryGirl.create(:join_request, user: user, joinable: entourage)
    expect(entourage.members).to eq([user])
  end

  it "has many chat messages" do
    entourage = FactoryGirl.create(:entourage)
    chat_message = FactoryGirl.create(:chat_message, messageable: entourage)
    expect(entourage.chat_messages).to eq([chat_message])
  end

  describe 'moderate after create' do
    it 'should not ping Slack if description is acceptable' do
      entourage = FactoryGirl.create(:entourage, description: 'Coucou, je veux donner des jouets.')
      expect(entourage).not_to receive(:ping_slack)
    end

    it 'should ping Slack if description is unacceptable' do
      entourage = FactoryGirl.build(
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

    it { expect(Entourage.where("metadata->>'starts_at' < ?", now + 1)).to eq [outing] }
    it { expect(Entourage.where("metadata->>'starts_at' > ?", now - 1)).to eq [outing] }
    it { expect(Entourage.where("metadata->>'starts_at' = ?", now    )).to eq [outing] }
    it { expect(Entourage.where("metadata->>'starts_at' between ? and ?", now - 1, now + 1)).to eq [outing] }

    it { expect(outing.metadata[:starts_at]).to be_a ActiveSupport::TimeWithZone }
    it { expect(outing.metadata[:starts_at].time_zone).to eq Time.zone }

    it { expect(outing.metadata).to eq(
      starts_at: now,
      display_address: "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris",
      place_name: "Café la Renaissance",
      street_address: "44 rue de l’Assomption, 75016 Paris, France",
      google_place_id: "foobar",
      :$id=>"urn:entourage:outing:metadata"
    ) }
    it { expect(build(:outing, default_metadata: {}).tap(&:save).errors.messages).to eq(
      metadata: ["did not contain a required property of 'starts_at'",
                 "did not contain a required property of 'place_name'",
                 "did not contain a required property of 'street_address'",
                 "did not contain a required property of 'google_place_id'"]
    ) }
    it { expect(build(:outing, metadata: {starts_at: "lol", street_address: 42}).tap(&:save).errors.messages).to eq(
      metadata: ["'starts_at' must be a valid ISO 8601 date/time string",
                 "'street_address' of type Fixnum did not match the following type: string"]
    ) }
  end

  describe "public accessibility" do
    it { expect(build(:entourage, group_type: :action, entourage_type: :ask_for_help, public: true).tap(&:save).errors.messages).to eq(
      public: ["n'est pas inclus(e) dans la liste"]
    ) }
  end

  it "has an uuid" do
    entourage = FactoryGirl.create(:entourage)

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

  describe '.find_by_id_or_uuid' do
    subject { Entourage.find_by_id_or_uuid identifier }

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
      # wraps subject in a Proc to allow use of `raise_error`
      def subject
        -> { super }
      end

      context "when searching with an integer id" do
        let(:identifier) { 1234 }
        it { is_expected.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with an string id" do
        let(:identifier) { "1234" }
        it { is_expected.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with a v1 uuid" do
        let(:identifier) { "59f213f2-7101-4c4c-b9a2-e298d9cb56af" }
        it { is_expected.to raise_error ActiveRecord::RecordNotFound }
      end

      context "when searching with a v2 uuid" do
        let(:identifier) { "emRCdKR0VOio" }
        it { is_expected.to raise_error ActiveRecord::RecordNotFound }
      end
    end
  end
end
