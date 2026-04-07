require 'rails_helper'
include CommunityHelper

RSpec.describe Outing, type: :model do
  let(:member) { FactoryBot.create(:public_user)}
  let(:sf_category) { :convivialite }
  let(:outing) { FactoryBot.create(:outing, :with_neighborhood, :with_recurrence, salesforce_id: "foo", sf_category: sf_category, interests: [:sport]) }
  let!(:chat_message) { FactoryBot.create(:chat_message, messageable: outing) }
  let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: member, status: :accepted) }

  it { expect(FactoryBot.build(:outing).save!).to be true }
  it { expect(FactoryBot.build(:outing, :with_neighborhood).save!).to be true }

  it { should belong_to(:user) }
  it { expect(outing.neighborhoods.count).to eq 1 }
  it { expect(outing.chat_messages.count).to eq 1 }

  describe 'member has to include creator' do
    before { outing.join_requests.where(user: outing.user).first.update_attribute(:status, :cancelled) }

    it { expect(outing.valid?).to be false }
  end

  describe 'dup' do
    let(:dup) { outing.dup }
    let(:result) { Outing.find(dup.id) }

    before { dup.save }

    it { expect(result.id).not_to eq(outing.id) }
    it { expect(result.chat_messages.count).to eq(0) }
    it { expect(result.salesforce_id).to be_nil }
    it { expect(result.members.count).to eq(1) }
    it { expect(result.members.first).to eq(dup.user) }
    it { expect(result.neighborhoods_entourages.count).to eq 1 }
    it { expect(result.neighborhoods.count).to eq 1 }
    it { expect(result.metadata[:starts_at]).to eq(outing.reload.metadata[:starts_at] + 7.days) }
    it { expect(result.sf_category).to eq('convivialite') }
    it { expect(result.interest_list).to eq(['sport']) }
    it { expect(result.taggings.map(&:id)).not_to eq(outing.taggings.map(&:id)) }
    it { expect(result.taggings.map(&:tag_id)).to match_array(outing.taggings.map(&:tag_id)) }
  end

  describe 'generate_initial_recurrences' do
    describe 'generates five occurences' do
      let(:starts_at) { 1.minute.from_now }
      let(:outing) { FactoryBot.create(:outing, :with_neighborhood, recurrency: 7, metadata: { starts_at: starts_at }) }
      let(:dates) { outing.siblings.map(&:starts_at).map{|date| date.iso8601(3)}.sort }

      it { expect(outing.siblings.count).to eq(5) }
      it { expect(dates).to include(starts_at.iso8601(3)) }
      it { expect(dates).to include((starts_at + 7.days).iso8601(3)) }
      it { expect(dates).to include((starts_at + 14.days).iso8601(3)) }
      it { expect(dates).to include((starts_at + 21.days).iso8601(3)) }
      it { expect(dates).to include((starts_at + 28.days).iso8601(3)) }
    end

    describe 'on create' do
      subject { FactoryBot.create(:outing, :with_neighborhood, recurrency: recurrency) }

      context 'with recurrency' do
        let(:recurrency) { 7 }

        it { expect { subject }.to change { Outing.count }.by(5) }
      end

      context 'without recurrency' do
        let(:recurrency) { nil }

        it { expect { subject }.to change { Outing.count }.by(1) }
      end
    end

    describe 'on update' do
      let(:outing) { FactoryBot.create(:outing, :with_neighborhood, recurrency: recurrency) }

      context 'from outing without recurrence to recurrence' do
        let(:recurrency) { nil }

        subject { outing.update_attribute(:recurrency, 7) }

        it { expect { subject }.to change { Outing.count }.by(4) }
      end

      context 'from outing without recurrence to without recurrence' do
        let(:recurrency) { nil }

        subject { outing.update_attribute(:recurrency, nil) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context 'from outing with recurrence to same recurrence' do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, 7) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context 'from outing with recurrence to another recurrence' do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, 14) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context 'from outing with recurrence to without recurrence' do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, nil) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end
    end
  end

  describe 'tagged_with_sf_category' do
    let(:sf_category) { :convivialite }
    let(:subject) { Outing.tagged_with_sf_category(with_sf_category) }

    context 'none' do
      let(:with_sf_category) { :passion_sport }

      it { expect(subject.pluck(:id)).to match_array([]) }
    end

    context 'match' do
      let(:with_sf_category) { :convivialite }

      it { expect(subject.pluck(:id)).to match_array([outing.id]) }
    end
  end

  describe 'papotage?' do
    it { expect(create(:outing, :outing_class, title: 'Papotage en ligne', online: true).papotage?).to eq(true) }
    it { expect(create(:outing, :outing_class, title: 'Papotage en ligne', online: false).papotage?).to eq(false) }
    it { expect(create(:outing, :outing_class, title: 'Discussion en ligne', online: true).papotage?).to eq(false) }
  end

  describe "#reserved_female=" do
    let(:outing) { create(:outing, :outing_class) }

    before { outing.reserved_female = true }

    it { expect(outing[:metadata][:reserved_female]).to eq(true) }
  end

  describe '#reset_unread_messages_if_blacklisted_or_deleted' do
    let(:outing) { create(:outing, status: 'open') }
    let(:join_request) { create :join_request, joinable: outing }

    before { outing.join_requests.update_all(unread_messages_count: 5) }

    context 'when status changes to blacklisted' do
      it 'resets unread_messages_count to 0 for all join_requests' do
        outing.update!(status: 'blacklisted')
        expect(outing.join_requests.pluck(:unread_messages_count)).to all(eq(0))
      end
    end

    context 'when status changes to closed' do
      it 'resets unread_messages_count to 0 for all join_requests' do
        outing.update!(status: 'closed')
        expect(outing.join_requests.pluck(:unread_messages_count)).to all(eq(0))
      end
    end

    context 'when status changes to another non-matching value' do
      it 'does not reset unread_messages_count' do
        outing.update!(status: 'suspended')
        expect(outing.join_requests.pluck(:unread_messages_count)).to all(eq(5))
      end
    end

    context 'when status does not change' do
      it 'does not trigger the reset' do
        outing.touch # met à jour updated_at sans changer status
        expect(outing.join_requests.pluck(:unread_messages_count)).to all(eq(5))
      end
    end
  end

  describe "#sibling_recurrence?" do
    subject { outing.sibling_recurrence? }

    context "when outing is not recurrent" do
      let(:outing) { create(:outing, :outing_class, recurrency_identifier: nil) }

      it { expect(subject).to eq false }
    end

    context "when outing is recurrent but has no recurrence record" do
      let(:outing) { create(:outing, :outing_class, recurrency_identifier: "abc123") }

      it { expect(subject).to eq false }
    end

    context "when recurrence exists but has no first_outing" do
      let(:recurrence) { create(:outing_recurrence, identifier: "abc123") }
      let(:outing) { create(:outing, :outing_class, recurrency_identifier: recurrence.identifier) }

      it { expect(subject).to eq false }
    end

    context "when outing is the first_outing of the recurrence" do
      let(:recurrence) { create(:outing_recurrence, identifier: "abc123") }
      let!(:outing) { create(:outing, :outing_class, recurrency_identifier: recurrence.identifier, metadata: { starts_at: 1.hour.from_now }) }
      let!(:second_outing) { create(:outing, :outing_class, recurrency_identifier: recurrence.identifier, metadata: { starts_at: 2.hours.from_now }) }

      it { expect(subject).to eq false }
    end

    context "when outing is a sibling in the recurrence" do
      let(:recurrence) { create(:outing_recurrence, identifier: "abc123") }
      let!(:first_outing) { create(:outing, :outing_class, recurrency_identifier: recurrence.identifier, metadata: { starts_at: 1.hour.from_now }) }
      let!(:outing) { create(:outing, :outing_class, recurrency_identifier: recurrence.identifier, metadata: { starts_at: 2.hours.from_now }) }

      it { expect(subject).to eq true }
    end
  end

  describe "#webinar?" do
    subject(:webinar?) { outing.webinar? }

    let(:outing) { create(:outing, :outing_class, online: online) }

    context "when outing is online and has a webinar tag" do
      let(:online) { true }

      before { outing.sf_category_list.add("atelier_femmes") }

      it { expect(webinar?).to be true }
    end

    context "when outing is offline" do
      let(:online) { false }

      before { outing.sf_category_list.add("atelier_femmes") }

      it { expect(webinar?).to be false }
    end

    context "when outing does not have webinar tags" do
      let(:online) { true }

      before { outing.sf_category_list.add("welcome_entourage_local") }

      it { expect(webinar?).to be false }
    end
  end

  describe "#first_steps?" do
    subject(:first_steps?) { outing.first_steps? }

    let(:outing) { create(:outing, :outing_class, online: online) }

    context "when outing is online and has a first_steps tag" do
      let(:online) { true }

      before { outing.sf_category_list.add("welcome_entourage_local") }

      it { expect(first_steps?).to be true }
    end

    context "when outing is offline" do
      let(:online) { false }

      before { outing.sf_category_list.add("welcome_entourage_local") }

      it { expect(first_steps?).to be false }
    end

    context "when outing does not have first_steps tags" do
      let(:online) { true }

      before { outing.sf_category_list.add("atelier_femmes") }

      it { expect(first_steps?).to be false }
    end
  end

  describe "#papotages?" do
    subject(:papotages?) { outing.papotages? }

    context "when title contains 'papotage'" do
      let(:outing) { create(:outing, :outing_class, online: true, title: "Grand papotage entre voisins") }

      it { expect(papotages?).to be true }
    end

    context "when title contains 'PAPOTAGE' (case insensitive)" do
      let(:outing) { create(:outing, :outing_class, online: true, title: "PAPOTAGE du dimanche") }

      it { expect(papotages?).to be true }
    end

    context "when title does not contain papotage" do
      let(:outing) { create(:outing, :outing_class, online: true, title: "Atelier cuisine") }

      it { expect(papotages?).to be false }
    end
  end
end
