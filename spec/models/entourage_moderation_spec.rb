require 'rails_helper'

RSpec.describe Neighborhood, :type => :model do
  describe 'auto_post_at_create' do
    let(:user) { create(:user) }
    let(:neighborhood) { create(:neighborhood, participants: [user]) }
    let!(:chat_message) { create(:chat_message, messageable: neighborhood) }
    let(:entourage) { create(:entourage, status: status, user: user, auto_post_at_create: auto_post_at_create) }
    let(:auto_post_at_create) { true }

    before { User.any_instance.stub(:default_neighborhood).and_return(neighborhood) }

    context 'when entourage_moderation is validated and entourage is valid' do
      let(:status) { :open }

      it { expect { entourage.set_moderation_dates_and_save }.to change { ChatMessage.count }.by 1 }

      context "chat_message has auto_post on default_neighborhood" do
        before { entourage.set_moderation_dates_and_save }

        it { expect(ChatMessage.last.auto_post_type).to eq("Neighborhood") }
        it { expect(ChatMessage.last.auto_post_id).to eq(neighborhood.id) }
      end
    end

    context 'when entourage_moderation is not validated' do
      let(:status) { :closed }

      it { expect { entourage.set_moderation_dates_and_save }.not_to change { ChatMessage.count } }
    end

    context 'when auto_post_at_create is false' do
      let(:status) { :open }
      let(:auto_post_at_create) { false }

      it { expect { entourage.set_moderation_dates_and_save }.not_to change { ChatMessage.count } }
    end

    context 'when auto_post chat_message already exists' do
      let(:status) { :open }
      let!(:chat_message) { create(:chat_message, messageable: neighborhood, auto_post_type: "Neighborhood", auto_post_id: neighborhood.id) }

      it { expect { entourage.set_moderation_dates_and_save }.not_to change { ChatMessage.count } }
    end
  end
end
