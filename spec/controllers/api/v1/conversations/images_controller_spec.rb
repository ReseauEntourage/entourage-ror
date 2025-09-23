require 'rails_helper'

describe Api::V1::Conversations::ImagesController do
  let(:user) { create(:pro_user) }

  let(:conversation) { create :conversation }
  let(:result) { JSON.parse(response.body) }

  let!(:chat_message_1) { create(:chat_message, messageable: conversation, user: user, image_url: 'chat_message_1.jpg') }
  let!(:chat_message_2) { create(:chat_message, messageable: conversation, user: user, image_url: 'chat_message_2.jpg') }
  # not in the same conversation
  let!(:chat_message_3) { create(:chat_message, user: user, image_url: 'chat_message_3.jpg') }

  let!(:image_1) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_1.jpg", destination_path: 'path_1', destination_size: :medium) }
  let!(:image_2) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_2.jpg", destination_path: 'path_2', destination_size: :medium) }
  let!(:image_3) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_3.jpg", destination_path: 'path_3', destination_size: :medium) }

  let!(:image_high_1) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_1.jpg", destination_path: 'path_high_1', destination_size: :high) }
  let!(:image_high_2) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_2.jpg", destination_path: 'path_high_2', destination_size: :high) }
  let!(:image_high_3) { create(:image_resize_action, path: "#{ChatMessage::BUCKET_PREFIX}/chat_message_3.jpg", destination_path: 'path_high_3', destination_size: :high) }

  describe 'GET index' do
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
          {
            "chat_message_id" => chat_message_1.id,
            "url" => "https://#{ENV['ENTOURAGE_IMAGES_BUCKET']}.s3.eu-west-1.amazonaws.com/path_1"
          },
          {
            "chat_message_id" => chat_message_2.id,
            "url" => "https://#{ENV['ENTOURAGE_IMAGES_BUCKET']}.s3.eu-west-1.amazonaws.com/path_2"
          }
        ]
      }) }
    end
  end

  describe 'GET show' do
    context 'not signed in' do
      before { get :show, params: { conversation_id: conversation.to_param, id: chat_message_1.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in but not in conversation' do
      before { get :show, params: { conversation_id: conversation.to_param, id: chat_message_1.to_param, token: user.token } }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in, in conversation but not a chat_message from conversation' do
      let!(:join_request) { create(:join_request, joinable: conversation, user: user, status: :accepted) }

      before { get :show, params: { conversation_id: conversation.to_param, id: chat_message_3.to_param, token: user.token } }

      it { expect(response.status).to eq(400) }
    end

    context 'signed in, in conversation and a chat_message from conversation' do
      let!(:join_request) { create(:join_request, joinable: conversation, user: user, status: :accepted) }

      before { get :show, params: { conversation_id: conversation.to_param, id: chat_message_1.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('image')}
      it { expect(result).to eq({
        'image' => {
          "chat_message_id" => chat_message_1.id,
          "url" => "https://#{ENV['ENTOURAGE_IMAGES_BUCKET']}.s3.eu-west-1.amazonaws.com/path_high_1"
        }
      }) }
    end
  end
end
