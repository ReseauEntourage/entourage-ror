require 'rails_helper'
include AuthHelper

describe Admin::SlackController do
  render_views

  ENV['SLACK_APP_VERIFICATION_TOKEN'] = 'slack-app-verification-token'

  describe 'POST #message_action' do
    context 'on entourage' do
      let(:entourage) { FactoryBot.create(:entourage)}
      let(:payload) { {
        actions: [{
          action_id: 'validate',
          value: "entourage_validation:#{entourage.id}",
        }],
        user: { name: 'John Doe' },
      } }

      before {
        allow(Experimental::EntourageSlack).to receive(:asset_url).and_return('https://fake.url')
        allow(Experimental::EntourageSlack).to receive(:links_url).and_return('https://fake.url')
      }

      context 'not signed in' do
        before { post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) } }

        it { expect(response.code).to eq('401') }
      end

      context 'signed in' do
        before {
          payload[:token] = 'slack-app-verification-token'
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('200') }
        it { expect(JSON.parse(response.body)).not_to be_nil }
        it { expect(JSON.parse(response.body).has_key? 'attachments').to be_truthy }
      end

      context 'validation message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('200') }
        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq('*:white_check_mark: <@John Doe> a validé cette action*') }
        it { expect(entourage.reload.status).to eq('open') }
        it { expect(entourage.reload.moderation).not_to be_nil }
        it { expect(entourage.reload.moderation.moderated_at).not_to be_nil }
      end

      context 'block message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          payload[:actions] = [{ action_id: 'block', value: payload[:actions][0][:value] }]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('200') }
        it { expect(JSON.parse(response.body)['attachments'].last['text']).to eq('*:no_entry_sign: <@John Doe> a bloqué cette action*') }
        it { expect(entourage.reload.status).to eq('blacklisted') }
        it { expect(entourage.reload.moderation).not_to be_nil }
        it { expect(entourage.reload.moderation.moderated_at).not_to be_nil }
      end

      context 'wrong message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          payload[:actions] = [{ action_id: 'foo', value: payload[:actions][0][:value] }]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('400') }
      end
    end

    context 'on neighborhood' do
      let(:neighborhood) { FactoryBot.create(:neighborhood)}
      let(:payload) { {
        actions: [{
          action_id: 'validate',
          value: "neighborhood_validation:#{neighborhood.id}"
        }],
        user: { name: 'John Doe' },
      } }

      before {
        allow(Experimental::NeighborhoodSlack).to receive(:links_url).and_return('https://fake.url')
      }

      context 'not signed in' do
        before { post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) } }

        it { expect(response.code).to eq('401') }
      end

      context 'signed in' do
        before {
          payload[:token] = 'slack-app-verification-token'
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('200') }
        it { expect(JSON.parse(response.body)).not_to be_nil }
        it { expect(JSON.parse(response.body).has_key? 'blocks').to be_truthy }
      end

      context 'validation message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('200') }
        it { expect(JSON.parse(response.body)['blocks'].first['text']['text']).to eq('*:white_check_mark: <@John Doe> a validé ce groupe de voisinage*') }
      end

      context 'block message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          payload[:actions] = [{ action_id: 'block', value: payload[:actions][0][:value] }]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(JSON.parse(response.body)['blocks'].first['text']['text']).to eq('*:no_entry_sign: <@John Doe> a bloqué ce groupe de voisinage*') }
      end

      context 'wrong message' do
        before {
          payload[:token] = 'slack-app-verification-token'
          payload[:actions] = [{ action_id: 'foo', value: payload[:actions][0][:value] }]
          post :message_action, params: { payload: ActiveSupport::JSON.encode(payload) }
        }

        it { expect(response.code).to eq('400') }
      end
    end
  end

  describe 'GET #entourage_links' do
    let(:entourage) { FactoryBot.create(:entourage)}
    before { get :entourage_links, params: { id: entourage.to_param } }

    it { expect(response.code).to eq('200') }
    it { expect(assigns(:entourage)).not_to be_nil }
    it { expect(assigns(:entourage).id).to eq(entourage.id) }
  end

  describe 'GET #neighborhood_links' do
    let(:neighborhood) { FactoryBot.create(:neighborhood)}
    before { get :neighborhood_links, params: { id: neighborhood.to_param } }

    it { expect(response.code).to eq('302') }
    it { should redirect_to edit_admin_neighborhood_path(neighborhood) }
  end
end
