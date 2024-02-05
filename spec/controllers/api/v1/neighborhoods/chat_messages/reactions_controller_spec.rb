require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessages::ReactionsController do
  let(:user) { create(:pro_user) }
  let(:neighborhood) { create :neighborhood }
  let(:chat_message) { create(:chat_message, messageable: neighborhood) }

  let(:result) { JSON.parse(response.body) }

  describe 'index' do
    let!(:user_reaction) { create(:user_reaction, instance: chat_message) }

    context "not signed in" do
      before { get :index, params: { neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('reactions')}
      it { expect(result).to eq({
        "reactions" => [{
          'chat_message_id' => user_reaction.instance_id,
          "reaction_id" => user_reaction.reaction_id,
          "reactions_count" => 1,
        }]
      }) }
    end
  end

  describe 'details' do
    let!(:user_reaction_1) { create(:user_reaction, instance: chat_message) }
    let!(:user_reaction_2) { create(:user_reaction, instance: chat_message) }

    context "not signed in" do
      before { get :details, params: { id: user_reaction_1.reaction_id, neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :details, params: { id: user_reaction_1.reaction_id, neighborhood_id: neighborhood.to_param, token: user.token, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('users') }
      it { expect(result['users'].count).to eq(1) }
      it { expect(result['users'][0]).to have_key('id') }
      it { expect(result['users'][0]).to have_key('display_name') }
      it { expect(result['users'][0]['id']).to eq(user_reaction_1.user_id) }
    end
  end

  describe 'users' do
    let!(:user_reaction_1) { create(:user_reaction, instance: chat_message) }
    let!(:user_reaction_2) { create(:user_reaction, instance: chat_message) }

    context "not signed in" do
      before { get :users, params: { neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { get :users, params: { neighborhood_id: neighborhood.to_param, token: user.token, chat_message_id: chat_message.id } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('user_reactions')}
      it { expect(result['user_reactions'].count).to eq(2)}
      it { expect(result['user_reactions']).to match_array([
        {
          'reaction_id' => user_reaction_1.reaction_id,
          'user' => {
            'id' => user_reaction_1.user_id,
            'lang' => user_reaction_1.user.lang,
            'display_name' => UserPresenter.new(user: user_reaction_1.user).display_name,
            'avatar_url' => nil,
            'community_roles' => []
          }
        },
        {
          'reaction_id' => user_reaction_2.reaction_id,
          'user' => {
            'id' => user_reaction_2.user_id,
            'lang' => user_reaction_2.user.lang,
            'display_name' => UserPresenter.new(user: user_reaction_2.user).display_name,
            'avatar_url' => nil,
            'community_roles' => []
          }
        },
      ]) }
    end
  end

  describe 'create' do
    let(:reaction) { create(:reaction) }
    let(:request) { post :create, params: { neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id, token: user.token, reaction_id: reaction.id } }

    context "not member" do
      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "member" do
      let!(:join_request) { create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      context "unexisting reaction for user" do
        context do
          before { request }

          it { expect(response.status).to eq(201) }
        end

        context do
          it { expect { request }.to change { UserReaction.count }.by(1) }
        end
      end

      context "existing reaction for user" do
        let!(:user_reaction) { create(:user_reaction, instance: chat_message, user: user) }

        context do
          before { request }

          it { expect(response.status).to eq(400) }
        end

        context do
          it { expect { request }.not_to change { UserReaction.count } }
        end
      end
    end
  end

  describe 'destroy' do
    let!(:user_reaction) { create(:user_reaction, user: user, instance: chat_message) }

    let(:request) { delete :destroy, params: { neighborhood_id: neighborhood.to_param, chat_message_id: chat_message.id, token: user.token } }

    context "not member" do
      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "member" do
      let!(:join_request) { create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      context "unexisting reaction for user" do
        let!(:user_reaction) { create(:user_reaction, instance: chat_message) }

        context do
          it { expect { request }.not_to change { UserReaction.count } }
        end

        context do
          before { request }

          it { expect(response.status).to eq(400) }
        end
      end

      context "existing reaction for user" do
        context do
          before { request }

          it { expect(response.status).to eq(200) }
        end

        context do
          it { expect { request }.to change { UserReaction.count }.by(-1) }
        end
      end
    end
  end
end
