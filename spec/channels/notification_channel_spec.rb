require 'rails_helper'

RSpec.describe NotificationChannel, type: :channel do
  let(:user) { create(:public_user) }

  describe "avec un utilisateur authentifié" do
    before { stub_connection current_user: user }

    it "confirme la souscription" do
      subscribe
      expect(subscription).to be_confirmed
    end

    it "streame depuis le canal dédié à l'utilisateur" do
      subscribe
      expect(subscription.streams).to include("notifications_#{user.id}")
    end

    it "arrête tous les streams lors de la désouscription" do
      subscribe
      expect { unsubscribe }.not_to raise_error
    end
  end

  describe "sans utilisateur authentifié" do
    before { stub_connection current_user: nil }

    it "rejette la souscription" do
      subscribe
      expect(subscription).to be_rejected
    end
  end

  describe ".broadcast_to_user" do
    it "diffuse des données sur le canal de l'utilisateur" do
      expect {
        NotificationChannel.broadcast_to_user(user, { message: "test" })
      }.to have_broadcasted_to("notifications_#{user.id}").with(message: "test")
    end
  end
end
