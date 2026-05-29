require 'rails_helper'

RSpec.describe OutingChatChannel, type: :channel do
  let(:user)   { create(:pro_user) }
  let(:outing) { create(:outing) }

  def member_join_request
    create(:join_request, joinable: outing, user: user, status: 'accepted')
  end

  # ─── Abonnement ────────────────────────────────────────────────────────────

  describe "subscribed" do
    before { stub_connection current_user: user }

    context "membre accepté de l'outing" do
      before { member_join_request }

      it "confirme l'abonnement" do
        subscribe(outing_id: outing.id)
        expect(subscription).to be_confirmed
      end

      it "streame depuis le canal de l'outing" do
        subscribe(outing_id: outing.id)
        expect(subscription.streams).to include("outing_chat:#{outing.id}")
      end
    end

    context "outing inexistant" do
      it "rejette l'abonnement" do
        subscribe(outing_id: 999_999)
        expect(subscription).to be_rejected
      end
    end

    context "non membre de l'outing" do
      it "rejette l'abonnement" do
        subscribe(outing_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "membre en attente (pending)" do
      before { create(:join_request, joinable: outing, user: user, status: 'pending') }

      it "rejette l'abonnement" do
        subscribe(outing_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "entourage non-outing (ex: action)" do
      let(:action) { create(:entourage, group_type: :action) }
      before { create(:join_request, joinable: action, user: user, status: 'accepted') }

      it "rejette l'abonnement" do
        subscribe(outing_id: action.id)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Broadcast ─────────────────────────────────────────────────────────────

  describe ".broadcast_new_message" do
    let(:message) do
      create(:chat_message,
        messageable: outing,
        user:        user,
        content:     "Bonjour !")
    end

    it "diffuse sur le canal de l'outing" do
      expect {
        OutingChatChannel.broadcast_new_message(message)
      }.to have_broadcasted_to("outing_chat:#{outing.id}")
        .with(hash_including(
          type:      "new_message",
          outing_id: outing.id,
          user_id:   user.id,
          message_id: message.id
        ))
    end
  end

  # ─── Déconnexion ───────────────────────────────────────────────────────────

  describe "unsubscribed" do
    before do
      stub_connection current_user: user
      member_join_request
      subscribe(outing_id: outing.id)
    end

    it "arrête tous les streams" do
      expect { unsubscribe }.not_to raise_error
    end
  end
end
