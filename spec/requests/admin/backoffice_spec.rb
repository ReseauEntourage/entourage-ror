require 'rails_helper'

# Vérifie que le backoffice admin fonctionne correctement après la migration
# des assets de Sprockets vers importmap-rails.
RSpec.describe "Admin backoffice après migration assets", type: :request do
  let(:admin) { create(:pro_user, admin: true) }

  # Authentification via le flow login réel (stub de l'authentificateur).
  def login_as_admin(user)
    allow(UserServices::UserAuthenticator)
      .to receive(:authenticate_by_phone_and_admin_password)
      .and_return(user)
    post admin_sessions_path, params: { phone: user.phone, admin_password: "test" }
  end

  # ─── Pages publiques (sans authentification) ─────────────────────────────

  describe "GET /admin/sessions/new (page de connexion)" do
    before { get new_admin_session_path }

    it { expect(response).to have_http_status(:ok) }

    it "inclut les balises importmap (Sprockets → importmap-rails)" do
      expect(response.body).to include('type="importmap"')
    end

    it "ne contient plus d'include Sprockets pour application.js" do
      expect(response.body).not_to match(%r{<script[^>]+src="[^"]*assets/application.*\.js})
    end

    it "inclut le CSS via Sprockets" do
      expect(response.body).to include("stylesheet")
    end
  end

  describe "GET /admin/password_resets/new" do
    before { get new_admin_password_reset_path }

    it { expect(response).to have_http_status(:ok) }

    it "inclut les balises importmap" do
      expect(response.body).to include('type="importmap"')
    end
  end

  # ─── Authentification ────────────────────────────────────────────────────

  describe "POST /admin/sessions (connexion admin)" do
    context "avec des identifiants valides" do
      before { login_as_admin(admin) }

      it "redirige après connexion (pas de 500)" do
        expect(response).to be_redirect
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it "pose le cookie user_id requis par ActionCable" do
        expect(cookies[:user_id]).to be_present
      end
    end

    context "pages protégées sans authentification" do
      it "redirige /admin/ vers login (pas de 500)" do
        get "/admin/"
        expect(response).to be_redirect
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it "redirige POST /admin/notifications vers login (pas de 500)" do
        post admin_notifications_path, params: { message: "Unauthorized" }
        expect(response).to be_redirect
        expect(response).not_to have_http_status(:internal_server_error)
      end
    end
  end

  # ─── Endpoint ActionCable (POST /admin/notifications) ────────────────────
  # Note : la diffusion WebSocket elle-même est testée dans
  # spec/controllers/admin/notifications_controller_spec.rb.

  describe "POST /admin/notifications (authentifié)" do
    before { login_as_admin(admin) }

    context "avec Accept: application/json" do
      before do
        post admin_notifications_path,
             params: { message: "Alerte backoffice", type: "warning" },
             headers: { "Accept" => "application/json" }
      end

      it { expect(response).to have_http_status(:ok) }

      it "retourne { status: 'broadcasted' }" do
        expect(JSON.parse(response.body)).to include("status" => "broadcasted")
      end
    end

    context "avec Accept: text/html" do
      before do
        post admin_notifications_path, params: { message: "Flash test" }
      end

      it "redirige (pas de 500)" do
        expect(response).to be_redirect
        expect(response).not_to have_http_status(:internal_server_error)
      end
    end
  end
end
