require 'rails_helper'
include AuthHelper

describe Admin::NotificationsController do
  let!(:admin) { admin_basic_login }

  describe 'POST create' do
    context 'réponse JSON' do
      before do
        post :create, params: { message: "Alerte modération", type: "warning" },
                      format: :json
      end

      it { expect(response).to have_http_status(:ok) }

      it "retourne le statut broadcasted" do
        expect(JSON.parse(response.body)).to include("status" => "broadcasted")
      end
    end

    context 'diffusion WebSocket' do
      it "envoie une notification sur le canal de l'admin via ActionCable" do
        expect {
          post :create, params: { message: "Test ActionCable", type: "info" },
                        format: :json
        }.to have_broadcasted_to("notifications_#{admin.id}")
          .with(hash_including(message: "Test ActionCable", type: "info"))
      end
    end

    context 'message par défaut' do
      it "utilise un message par défaut si aucun message fourni" do
        expect {
          post :create, params: {}, format: :json
        }.to have_broadcasted_to("notifications_#{admin.id}")
          .with(hash_including(message: "Notification de test"))
      end
    end

    context 'réponse HTML (redirect)' do
      before { post :create, params: { message: "Redirect test" } }

      it { expect(response).to be_redirect }
    end

    context 'authentification requise' do
      before do
        session[:user_id] = nil
        session[:admin_user_id] = nil
      end

      it "redirige si non authentifié" do
        post :create, params: { message: "Unauthorized" }, format: :json
        expect(response).to be_redirect
      end
    end
  end
end
