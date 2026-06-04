require 'rails_helper'

RSpec.describe "Admin layout après migration assets", type: :request do
  # GET /admin/sessions/new — page de connexion, accessible sans auth, layout 'login'
  # La route ne nécessite pas de contrainte de sous-domaine
  before { get "/admin/sessions/new" }

  it "répond avec succès" do
    expect(response).to have_http_status(:ok)
  end

  it "inclut les balises importmap (migration Sprockets → importmap-rails réussie)" do
    expect(response.body).to include('type="importmap"')
  end

  it "n'inclut plus javascript_include_tag Sprockets pour application.js" do
    expect(response.body).not_to match(%r{<script[^>]+src="[^"]*assets/application.*\.js})
  end

  it "inclut le stylesheet CSS via Sprockets" do
    expect(response.body).to include("stylesheet")
  end

  it "inclut le lien vers application.css" do
    expect(response.body).to include("application")
  end
end
