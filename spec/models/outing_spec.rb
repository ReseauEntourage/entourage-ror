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

  describe "member has to include creator" do
    before { outing.join_requests.where(user: outing.user).first.update_attribute(:status, :cancelled) }

    it { expect(outing.valid?).to be false }
  end

  describe "dup" do
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
    it { expect(result.sf_category).to eq("convivialite") }
    it { expect(result.interest_list).to eq(["sport"]) }
    it { expect(result.taggings.map(&:id)).not_to eq(outing.taggings.map(&:id)) }
    it { expect(result.taggings.map(&:tag_id)).to eq(outing.taggings.map(&:tag_id)) }
  end

  describe "generate_initial_recurrences" do
    describe "generates five occurences" do
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

    describe "on create" do
      subject { FactoryBot.create(:outing, :with_neighborhood, recurrency: recurrency) }

      context "with recurrency" do
        let(:recurrency) { 7 }

        it { expect { subject }.to change { Outing.count }.by(5) }
      end

      context "without recurrency" do
        let(:recurrency) { nil }

        it { expect { subject }.to change { Outing.count }.by(1) }
      end
    end

    describe "on update" do
      let(:outing) { FactoryBot.create(:outing, :with_neighborhood, recurrency: recurrency) }

      context "from outing without recurrence to recurrence" do
        let(:recurrency) { nil }

        subject { outing.update_attribute(:recurrency, 7) }

        it { expect { subject }.to change { Outing.count }.by(4) }
      end

      context "from outing without recurrence to without recurrence" do
        let(:recurrency) { nil }

        subject { outing.update_attribute(:recurrency, nil) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context "from outing with recurrence to same recurrence" do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, 7) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context "from outing with recurrence to another recurrence" do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, 14) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end

      context "from outing with recurrence to without recurrence" do
        let(:recurrency) { 7 }

        subject { outing.update_attribute(:recurrency, nil) }

        it { expect { subject }.to change { Outing.count }.by(0) }
      end
    end
  end

  describe "tagged_with_sf_category" do
    let(:sf_category) { :convivialite }
    let(:subject) { Outing.tagged_with_sf_category(with_sf_category) }

    context "none" do
      let(:with_sf_category) { :passion_sport }

      it { expect(subject.pluck(:id)).to match_array([]) }
    end

    context "match" do
      let(:with_sf_category) { :convivialite }

      it { expect(subject.pluck(:id)).to match_array([outing.id]) }
    end
  end
end
