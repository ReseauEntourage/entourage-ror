require 'rails_helper'
include CommunityHelper

RSpec.describe Resource, type: :model do
  it { expect(FactoryBot.build(:chat_message).save).to be true }

  describe "has a v2 uuid" do
    let(:resource) { create :resource }

    describe "format" do
      it { expect(resource.uuid_v2).not_to be_nil }
      it { expect(resource.uuid_v2[0]).to eq 'e' }
      it { expect(resource.uuid_v2.length).to eq 12 }
    end
  end
end
