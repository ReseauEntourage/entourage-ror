require 'rails_helper'

describe Api::V1::Tours::ChatMessagesController do

  let(:tour) { FactoryGirl.create(:tour) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }
      let!(:chat_messages) { FactoryGirl.create_list(:chat_message, 2, messageable: tour) }
      before { get :index, tour_id: tour.to_param, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to eq({"chat_messages"=>
                                                     [{
                                                          "id"=>chat_messages.last.id,
                                                          "content"=>"MyText",
                                                          "user_id"=>chat_messages.last.user_id,
                                                          "created_at"=>chat_messages.last.created_at.iso8601(3)
                                                      },
                                                      {
                                                          "id"=>chat_messages.first.id,
                                                          "content"=>"MyText",
                                                          "user_id"=>chat_messages.first.user_id,
                                                          "created_at"=>chat_messages.first.created_at.iso8601(3)
                                                      }]}) }
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"} }
      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }
      context "valid params" do
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(1) }
        it { expect(JSON.parse(response.body)).to eq({"chat_message"=>
                                                          {"id"=>ChatMessage.first.id,
                                                           "content"=>"foobar",
                                                           "user_id"=>user.id,
                                                           "created_at"=>ChatMessage.first.created_at.iso8601(3)
                                                          }}) }
      end

      context "invalid params" do
        before { post :create, tour_id: tour.to_param, chat_message: {content: nil}, token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(ChatMessage.count).to eq(0) }
      end
    end
  end
end