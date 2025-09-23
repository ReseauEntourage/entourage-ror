require 'rails_helper'

describe Api::V1::Conversations::ImagesController do
  let(:user) { create(:pro_user) }

  let(:conversation) { create :conversation }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:chat_message_1) { create(:chat_message, messageable: conversation, user: user, image_url: 'chat_message_1.jpg') }
    let!(:chat_message_2) { create(:chat_message, messageable: conversation, user: user, image_url: 'chat_message_2.jpg') }
    let!(:image_1) { create(:image_resize_action, path: 'chat_message_1.jpg', destination_path: 'path_1', destination_size: :medium) }
    let!(:image_2) { create(:image_resize_action, path: 'chat_message_2.jpg', destination_path: 'path_2', destination_size: :medium) }

    context 'not signed in' do
      before { get :index, params: { conversation_id: conversation.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in but not in conversation' do
      before { get :index, params: { conversation_id: conversation.to_param, token: user.token } }

      it { expect(response.status).to eq(401) }
    end

    context "signed and in conversation" do
      let!(:join_request) { create(:join_request, joinable: conversation, user: user, status: :accepted) }

      before { get :index, params: { conversation_id: conversation.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('images')}
      it { expect(result).to eq({
        'images' => [
          "https://#{ENV['ENTOURAGE_IMAGES_BUCKET']}.s3.eu-west-1.amazonaws.com/path_1",
          "https://#{ENV['ENTOURAGE_IMAGES_BUCKET']}.s3.eu-west-1.amazonaws.com/path_2"
        ]
      }) }
    end

  end
end
