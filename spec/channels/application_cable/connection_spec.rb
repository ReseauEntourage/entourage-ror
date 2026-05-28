require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:public_user) }

  def signed_token(user_id)
    Rails.application.message_verifier(:cable).generate(user_id, expires_in: 24.hours)
  end

  describe "authentification par token URL (méthode principale)" do
    it "établit la connexion avec un token signé valide" do
      connect "/cable", params: { token: signed_token(user.id) }
      expect(connection.current_user).to eq(user)
    end

    it "rejette la connexion avec un token invalide" do
      expect {
        connect "/cable", params: { token: "token_falsifie" }
      }.to have_rejected_connection
    end

    it "rejette si le user_id du token n'existe pas en base" do
      expect {
        connect "/cable", params: { token: signed_token(999_999) }
      }.to have_rejected_connection
    end
  end

  describe "authentification par cookie signé (fallback)" do
    it "établit la connexion avec un cookie user_id valide" do
      cookies.signed[:user_id] = user.id
      connect "/cable"
      expect(connection.current_user).to eq(user)
    end
  end

  describe "sans authentification" do
    it "rejette la connexion" do
      expect { connect "/cable" }.to have_rejected_connection
    end
  end
end
