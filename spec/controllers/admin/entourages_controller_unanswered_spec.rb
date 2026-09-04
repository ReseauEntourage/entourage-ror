require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController do
  let!(:user) { admin_basic_login }

  describe 'GET unanswered' do
    let!(:creator) { FactoryBot.create(:pro_user) }
    let!(:participant) { FactoryBot.create(:pro_user) }

    let!(:awaiting_reply) { FactoryBot.create(:entourage, status: 'open', user: creator) }
    let!(:already_answered) { FactoryBot.create(:entourage, status: 'open', user: creator) }
    let!(:too_recent) { FactoryBot.create(:entourage, status: 'open', user: creator) }

    before do
      FactoryBot.create(:chat_message, messageable: awaiting_reply, user: participant, created_at: 5.days.ago)

      FactoryBot.create(:chat_message, messageable: already_answered, user: participant, created_at: 5.days.ago)
      FactoryBot.create(:chat_message, messageable: already_answered, user: creator, created_at: 4.days.ago)

      FactoryBot.create(:chat_message, messageable: too_recent, user: participant, created_at: 1.hour.ago)

      get :unanswered, params: { days: 3 }
    end

    it { expect(response).to be_successful }
    it { expect(assigns(:entourages)).to include(awaiting_reply) }
    it { expect(assigns(:entourages)).not_to include(already_answered) }
    it { expect(assigns(:entourages)).not_to include(too_recent) }

    it 'exposes the last sender and date' do
      row = assigns(:entourages).find { |e| e.id == awaiting_reply.id }
      expect(row.last_message_user_id).to eq(participant.id)
    end
  end
end
