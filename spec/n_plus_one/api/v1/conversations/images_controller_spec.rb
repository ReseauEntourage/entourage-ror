require 'rails_helper'

describe Api::V1::Conversations::ImagesController, type: :controller do
  let(:user) { create :pro_user }
  let(:conversation) { create :conversation, participants: [user] }

  def create_chat_message_with_image(sizes:)
    chat_message = create :chat_message, messageable: conversation, user: create(:public_user), image_url: "#{SecureRandom.hex(6)}.jpg"

    sizes.each do |size|
      create :image_resize_action,
        path: "#{ChatMessage::BUCKET_PREFIX}/#{chat_message.image_url}",
        destination_path: "#{size}/#{chat_message.image_url}",
        destination_size: size
    end
  end

  def perform_request
    get :index, params: { conversation_id: conversation.to_param, token: user.token }
  end

  def returned_items_count
    JSON.parse(response.body)['images'].size
  end

  describe 'GET index' do
    context 'images resized in medium (preloaded)' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times { create_chat_message_with_image(sizes: [:medium, :high]) }
        end
      end
    end

    # une image pas (encore) redimensionnée en medium retombe sur image_url_with_size(:high)
    context 'images without medium resize (fallback on high size)' do
      it_behaves_like 'an endpoint without N+1 queries' do
        def populate(count)
          count.times { create_chat_message_with_image(sizes: [:high]) }
        end
      end
    end
  end
end
