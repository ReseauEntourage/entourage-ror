require 'rails_helper'

RSpec.describe Neighborhood, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }

  describe 'members count' do
    let(:neighborhood) { FactoryBot.create :neighborhood }
    let(:member) { FactoryBot.create :public_user }
    let!(:join_request) { FactoryBot.create :join_request, user: member, joinable: neighborhood, status: status }

    subject { neighborhood.members.pluck(:id) }

    context 'member accepted' do
      let(:status) { :accepted }

      it { expect(subject).to include(member.id) }
    end

    context 'member cancelled' do
      let(:status) { :cancelled }

      it { expect(subject).not_to include(member.id) }
    end
  end

  describe 'inside_perimeter' do
    let!(:neighborhood) { FactoryBot.create :neighborhood, latitude: 48.86, longitude: 2.35 }
    let(:travel_distance) { 1 }

    # distance is about 26_500 meters
    subject { Neighborhood.inside_perimeter(48.80, 2, travel_distance) }

    context 'travel_distance is too low' do
      it { expect(subject.count).to eq(0) }
    end

    context 'travel_distance is again too low' do
      let(:travel_distance) { 25 }
      it { expect(subject.count).to eq(0) }
    end

    context 'travel_distance is enough' do
      let(:travel_distance) { 28 }
      it { expect(subject.count).to eq(1) }
    end
  end

  describe 'order_by_distance_from' do
    let!(:paris) { FactoryBot.create :neighborhood, latitude: 48.86, longitude: 2.35 }
    let!(:nantes) { FactoryBot.create :neighborhood, latitude: 47.22, longitude: -1.55 }

    subject { Neighborhood.order_by_distance_from(latitude, longitude).pluck(:id) }

    context 'from angers' do
      let(:latitude) { 47.48 }
      let(:longitude) { -0.56 }

      it { expect(subject).to eq([nantes.id, paris.id]) }
    end

    context 'from versailles' do
      let(:latitude) { 48.80 }
      let(:longitude) { 2.13 }

      it { expect(subject).to eq([paris.id, nantes.id]) }
    end
  end

  describe 'order_by_interests_matching' do
    let!(:sport) { FactoryBot.create :neighborhood, name: 'sport', interests: [:sport] }
    let!(:nature_animals) { FactoryBot.create :neighborhood, name: 'nature_animals', interests: [:nature, :animaux] }
    let!(:nature_jeux) { FactoryBot.create :neighborhood, name: 'nature_jeux', interests: [:nature, :jeux] }
    let!(:other) { FactoryBot.create :neighborhood, name: 'other', interests: [:other], other_interest: 'foo' }
    let!(:none) { FactoryBot.create :neighborhood, name: 'none', interests: [] }

    subject { Neighborhood.order_by_interests_matching(interests).pluck(:name) }

    context 'on nature' do
      let(:interests) { [:nature] }

      it { expect(subject[0..1]).to match_array([nature_animals.name, nature_jeux.name]) }
      it { expect(subject[2..-1]).to match_array([sport.name, other.name, none.name]) }
    end

    context 'on jeux' do
      let(:interests) { [:jeux] }

      it { expect(subject[0]).to eq(nature_jeux.name) }
      it { expect(subject[1..-1]).to match_array([sport.name, nature_animals.name, other.name, none.name]) }
    end

    context 'on nature, jeux' do
      let(:interests) { [:nature, :jeux] }

      it { expect(subject[0]).to eq(nature_jeux.name) }
      it { expect(subject[1]).to eq(nature_animals.name) }
      it { expect(subject[2..-1]).to match_array([sport.name, other.name, none.name]) }
    end
  end

  describe 'order_by_outings' do
    subject { Neighborhood.order_by_outings.pluck(:id) }

    let(:outing_1) { FactoryBot.create :outing, :outing_class, created_at: Time.now }
    let(:outing_2) { FactoryBot.create :outing, :outing_class, created_at: Time.now }

    let!(:without_outing) { FactoryBot.create :neighborhood, outings: [] }
    let!(:with_outing) { FactoryBot.create :neighborhood, outings: [outing_1] }
    let!(:with_outings) { FactoryBot.create :neighborhood, outings: [outing_1, outing_2] }

    it { expect(subject).to eq([with_outings.id, with_outing.id, without_outing.id]) }
  end

  describe 'order_by_chat_messages' do
    subject { Neighborhood.order_by_chat_messages.pluck(:id) }

    let!(:without_chat_message) { FactoryBot.create :neighborhood }
    let(:with_chat_message) { FactoryBot.create :neighborhood }
    let(:with_chat_messages) { FactoryBot.create :neighborhood }

    let!(:chat_message_1) { FactoryBot.create :chat_message, created_at: Time.now, messageable: with_chat_message }
    let!(:chat_message_2) { FactoryBot.create :chat_message, created_at: Time.now, messageable: with_chat_messages }
    let!(:chat_message_3) { FactoryBot.create :chat_message, created_at: Time.now, messageable: with_chat_messages }


    it { expect(subject).to eq([with_chat_messages.id, with_chat_message.id, without_chat_message.id]) }
  end

  describe "status_changed_at" do
    let(:neighborhood) { FactoryBot.create(:neighborhood, status: :open) }

    context 'set status_changed_at' do
      before { neighborhood.update(status: :closed) }

      it { expect(neighborhood.status).to eq("closed") }
      it { expect(neighborhood.status_changed_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  describe "notify_slack" do
    let(:neighborhood) { build(:neighborhood) }

    before {
      allow(Experimental::NeighborhoodSlack).to receive(:notify)

      neighborhood.save
    }

    it { expect(Experimental::NeighborhoodSlack).to have_received(:notify) }
  end
end
