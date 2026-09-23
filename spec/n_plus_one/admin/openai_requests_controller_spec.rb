require 'rails_helper'
include AuthHelper

describe Admin::OpenaiRequestsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  before do
    create :openai_assistant, module_type: :matching
    create :openai_assistant, module_type: :offense
  end

  describe 'GET index' do
    context 'module_type matching (défaut)' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            action = create(:entourage, user: create(:public_user))
            OpenaiRequest.where(instance: action).delete_all
            create :openai_request, instance: action, instance_class: 'Entourage', module_type: :matching,
              response: { content: [{ type: 'text', text: { value: '{"recommandations": [{"type": "resource", "id": "1"}]}' } }] }.to_json
          end
        end

        def perform_request
          get :index
        end

        def returned_items_count
          assigns(:openai_requests).to_a.size
        end
      end
    end

    context 'module_type offense' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times do
            chat_message = create(:chat_message, user: create(:public_user))
            OpenaiRequest.where(instance: chat_message).delete_all
            create :openai_request, instance: chat_message, instance_class: 'ChatMessage', module_type: :offense,
              response: { content: [{ type: 'text', text: { value: '{"result": true}' } }] }.to_json
          end
        end

        def perform_request
          get :index, params: { module_type: :offense }
        end

        def returned_items_count
          assigns(:openai_requests).to_a.size
        end
      end
    end
  end
end
