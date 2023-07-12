require 'rails_helper'
include AuthHelper

describe Admin::SlackController do
  render_views

  ENV["SLACK_APP_VERIFICATION_TOKEN"] = "slack-app-verification-token"

  describe 'POST #message_action' do
    context "on entourage" do
      let(:entourage) { FactoryBot.create(:entourage)}
      let(:payload) { {
        callback_id: "entourage_validation:#{entourage.id}",
        user: { name: 'John Doe' },
        actions: [ { value: "validate" } ]
      } }

      before {
        allow(Experimental::EntourageSlack).to receive(:asset_url).and_return('https://fake.url')
        allow(Experimental::EntourageSlack).to receive(:links_url).and_return('https://fake.url')
      }

      context "not signed in" do
        before { post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) } }

        it { expect(response.code).to eq("401") }
      end

      context "signed in" do
        before {
          payload[:token] = "slack-app-verification-token"
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq("200") }
        it { expect(JSON.parse(response.body)).not_to be_nil }
        it { expect(JSON.parse(response.body).has_key? 'attachments').to be_truthy }
      end

      context "validation message" do
        before {
          payload[:token] = "slack-app-verification-token"
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq("*:white_check_mark: <@John Doe> a validé cette action*") }
        it { expect(entourage.reload.status).to eq("open") }
        it { expect(entourage.reload.moderation).not_to be_nil }
        it { expect(entourage.reload.moderation.moderated_at).not_to be_nil }
      end

      context "block message" do
        before {
          payload[:token] = "slack-app-verification-token"
          payload[:actions] = [ { value: "block" } ]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq("*:no_entry_sign: <@John Doe> a bloqué cette action*") }
        it { expect(entourage.reload.status).to eq("blacklisted") }
        it { expect(entourage.reload.moderation).not_to be_nil }
        it { expect(entourage.reload.moderation.moderated_at).not_to be_nil }
      end

      context "wrong message" do
        before {
          payload[:token] = "slack-app-verification-token"
          payload[:actions] = [ { value: "foo" } ]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq("400") }
      end
    end

    context "on neighborhood" do
      let(:neighborhood) { FactoryBot.create(:neighborhood)}
      let(:payload) { {
        callback_id: "neighborhood_validation:#{neighborhood.id}",
        user: { name: 'John Doe' },
        actions: [ { value: "validate" } ]
      } }

      before {
        allow(Experimental::NeighborhoodSlack).to receive(:links_url).and_return('https://fake.url')
      }

      context "not signed in" do
        before { post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) } }

        it { expect(response.code).to eq("401") }
      end

      context "signed in" do
        before {
          payload[:token] = "slack-app-verification-token"
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq("200") }
        it { expect(JSON.parse(response.body)).not_to be_nil }
        it { expect(JSON.parse(response.body).has_key? 'attachments').to be_truthy }
      end

      context "validation message" do
        before {
          payload[:token] = "slack-app-verification-token"
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq("200") }
        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq("*:white_check_mark: <@John Doe> a validé ce groupe de voisinage*") }
      end

      context "block message" do
        before {
          payload[:token] = "slack-app-verification-token"
          payload[:actions] = [ { value: "block" } ]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq("*:no_entry_sign: <@John Doe> a bloqué ce groupe de voisinage*") }
      end

      context "wrong message" do
        before {
          payload[:token] = "slack-app-verification-token"
          payload[:actions] = [ { value: "foo" } ]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq("400") }
      end
    end
  end

  describe 'GET #entourage_links' do
    let(:entourage) { FactoryBot.create(:entourage)}
    before { get :entourage_links, params: { id: entourage.to_param } }

    it { expect(response.code).to eq("200") }
    it { expect(assigns(:entourage)).not_to be_nil }
    it { expect(assigns(:entourage).id).to eq(entourage.id) }
  end

  describe 'GET #neighborhood_links' do
    let(:neighborhood) { FactoryBot.create(:neighborhood)}
    before { get :neighborhood_links, params: { id: neighborhood.to_param } }

    it { expect(response.code).to eq("302") }
    it { should redirect_to edit_admin_neighborhood_path(neighborhood) }
  end

  # @deprecated
  # describe 'GET #csv' do
  #   let(:params) { {
  #     filename: 'filename',
  #     option: 'option',
  #   }}

  #   context "not signed in" do
  #     before { get :csv, params: params }

  #     it { expect(response.code).to eq("401") }
  #   end

  #   context "signed in" do
  #     let!(:user) { admin_basic_login }
  #     before { get :csv, params: params }

  #     it { expect(response.code).to eq("200") }
  #   end

  #   context "redirect_to aws path" do
  #     let!(:user) { admin_basic_login }
  #     before {
  #       params['option'] = 'display'
  #       get :csv, params: params
  #     }

  #     it { should redirect_to assigns(:url) }
  #   end

  #   context "download file" do
  #     let!(:user) { admin_basic_login }
  #     before {
  #       allow_any_instance_of(Storage::Bucket).to receive(:url_for).and_return('https://fake.url')
  #       stub_request(:get, "https://fake.url/").to_return(status: 200, body: "", headers: {})

  #       params['option'] = 'download'
  #       get :csv, params: params
  #     }

  #     it { expect(response.headers).not_to be_nil }
  #     it { expect(response.headers['Content-Disposition']).not_to be_nil }
  #     it { expect(response.headers['Content-Disposition']).to eq 'inline; filename="filename.csv"; filename*=UTF-8\'\'filename.csv' }
  #   end
  # end
end
