require 'rails_helper'

describe Api::V1::Outings::ChatMessages::SurveyResponsesController do
  let(:user) { create(:pro_user) }
  let(:outing) { create :outing }
  let(:chat_message) { create(:chat_message, messageable: outing) }

  let(:result) { JSON.parse(response.body) }

  describe 'create' do
    let(:request) { post :create, params: { outing_id: outing.to_param, chat_message_id: chat_message.id, token: user.token, responses: [true, false] } }

    context "not member" do
      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "member" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: :accepted) }

      context "unexisting response for user" do
        context do
          before { request }

          it { expect(response.status).to eq(201) }
        end

        context do
          it { expect { request }.to change { SurveyResponse.count }.by(1) }
        end
      end

      context "existing response for user" do
        let!(:survey_response) { create(:survey_response, chat_message: chat_message, user: user, responses: [false, true]) }

        context do
          before { request }

          it { expect(response.status).to eq(400) }
        end

        context do
          it { expect { request }.not_to change { SurveyResponse.count } }
        end
      end
    end
  end

  describe 'destroy' do
    let!(:survey_response) { create(:survey_response, user: user, chat_message: chat_message) }

    let(:request) { delete :destroy, params: { outing_id: outing.to_param, chat_message_id: chat_message.id, token: user.token } }

    context "not member" do
      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "member" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: :accepted) }

      context "unexisting survey_response for user" do
        let!(:survey_response) { create(:survey_response, chat_message: chat_message) }

        context do
          it { expect { request }.not_to change { SurveyResponse.count } }
        end

        context do
          before { request }

          it { expect(response.status).to eq(400) }
        end
      end

      context "existing survey_response for user" do
        context do
          before { request }

          it { expect(response.status).to eq(200) }
        end

        context do
          it { expect { request }.to change { SurveyResponse.count }.by(-1) }
        end
      end
    end
  end
end
