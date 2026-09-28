require 'rails_helper'
include AuthHelper

describe Admin::OpenaiAssistantsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        @version ||= 0

        count.times do
          @version += 1
          create :openai_assistant, version: @version, module_type: "module_#{@version}", prompt: "prompt #{@version}"
        end
      end

      def perform_request
        get :index
      end

      def returned_items_count
        assigns(:openai_assistants).to_a.size
      end
    end
  end
end
