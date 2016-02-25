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
end