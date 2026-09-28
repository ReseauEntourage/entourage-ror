require 'rails_helper'
include AuthHelper

describe Admin::ConversationsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  describe 'GET index' do
    def create_conversation(deleted_last_message: false)
      recipient = create(:public_user, avatar_key: 'avatar.jpg')
      conversation = create :conversation, user: recipient, participants: [user, recipient]
      message = create :chat_message, messageable: conversation, user: recipient, content: 'hello'

      if deleted_last_message
        # branche "Ce message a été supprimé par <deleter>" de la vue (_conversations.html.erb)
        message.update_columns(status: :deleted, comments_count: 1, deleter_id: create(:public_user).id, deleted_at: Time.zone.now)
      end

      conversation.update_columns(number_of_root_chat_messages: 1, feed_updated_at: Time.zone.now)
    end

    context 'with a regular last message' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times { create_conversation }
        end

        def perform_request
          get :index
        end

        def returned_items_count
          assigns(:conversations).to_a.size
        end
      end
    end

    context 'with a deleted last message' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times { create_conversation(deleted_last_message: true) }
        end

        def perform_request
          get :index
        end

        def returned_items_count
          assigns(:conversations).to_a.size
        end
      end
    end
  end
end
