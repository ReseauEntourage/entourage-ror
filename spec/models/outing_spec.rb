require 'rails_helper'
include CommunityHelper

RSpec.describe Outing, type: :model do
  let(:member) { FactoryBot.create(:public_user)}
  let(:outing) { FactoryBot.create(:outing, :with_neighborhood, :with_recurrence) }
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

    context 'neighborhoods' do
      before { dup.save! }

      it { expect(dup.chat_messages.count).to eq(0) }
      it { expect(dup.members.count).to eq(1) }
      it { expect(dup.members.first).to eq(dup.user) }
      it { expect(dup.neighborhoods_entourages.count).to eq 1 }
      it { expect(dup.neighborhoods.count).to eq 1 }
      it { expect(dup.metadata[:starts_at]).to eq(outing.reload.metadata[:starts_at] + 7.days) }
    end
  end
end
