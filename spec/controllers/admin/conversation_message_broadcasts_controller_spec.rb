require 'rails_helper'
include AuthHelper

describe Admin::ConversationMessageBroadcastsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context "has conversation_message_broadcasts" do
      let!(:conversation_message_broadcast_list) { FactoryGirl.create_list(:conversation_message_broadcast, 2) }
      before { get :index }

      it { expect(assigns(:conversation_message_broadcasts)).to match_array(conversation_message_broadcast_list) }
    end

    context "has no conversation_message_broadcasts" do
      before { get :index }
      it { expect(assigns(:conversation_message_broadcasts)).to eq([]) }
    end
  end

  # filters
  describe 'GET #index goal filter' do
    let!(:ask_for_help) { FactoryGirl.create(:conversation_message_broadcast, goal: 'ask_for_help') }
    let!(:offer_help) { FactoryGirl.create(:conversation_message_broadcast, goal: 'offer_help') }

    context "has goal conversation_message_broadcasts" do
      before { get :index, goal: 'ask_for_help' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([ask_for_help]) }
    end

    context "has goal conversation_message_broadcasts" do
      before { get :index, goal: 'offer_help' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([offer_help]) }
    end
  end

  describe 'GET #index area filter' do
    let!(:dep_75) { FactoryGirl.create(:conversation_message_broadcast, area: 'dep_75') }
    let!(:hors_zone) { FactoryGirl.create(:conversation_message_broadcast, area: 'hors_zone') }

    context "has area conversation_message_broadcasts" do
      before { get :index, area: 'dep_75' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([dep_75]) }
    end

    context "has area conversation_message_broadcasts" do
      before { get :index, area: 'hors_zone' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([hors_zone]) }
    end
  end

  describe 'GET #index status filter' do
    let!(:draft) { FactoryGirl.create(:conversation_message_broadcast, status: 'draft') }
    let!(:archived) { FactoryGirl.create(:conversation_message_broadcast, status: 'archived', archived_at: Time.now) }

    context "has default status conversation_message_broadcasts" do
      before { get :index }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([draft]) }
    end

    context "has status conversation_message_broadcasts" do
      before { get :index, status: 'draft' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([draft]) }
    end

    context "has status conversation_message_broadcasts" do
      before { get :index, status: 'archived' }
      it { expect(assigns(:conversation_message_broadcasts)).to match_array([archived]) }
    end
  end

  describe "GET #new" do
    before { get :new }
    it { expect(assigns(:conversation_message_broadcast)).to be_a_new(ConversationMessageBroadcast) }
  end

  describe "POST #create" do
    context "create success" do
      let(:conversation_message_broadcast) { post :create, { 'conversation_message_broadcast' => {
        area: 'dep_75',
        content: 'Contenu du broadcast',
        goal: 'ask_for_help',
        title: 'Titre du broadcast'
      } } }
      it { expect { conversation_message_broadcast }.to change { ConversationMessageBroadcast.count }.by(1) }
    end

    context "create failure" do
      let(:conversation_message_broadcast) { post :create, { 'conversation_message_broadcast' => {
        area: nil,
        content: 'Contenu du broadcast',
        goal: 'ask_for_help',
        title: 'Titre du broadcast'
      } } }
        it { expect { conversation_message_broadcast }.to change { ConversationMessageBroadcast.count }.by(0) }
    end
  end

  describe "GET #edit" do
    let!(:conversation_message_broadcast) { FactoryGirl.create(:conversation_message_broadcast) }
    before { get :edit, id: conversation_message_broadcast.to_param }
    it { expect(assigns(:conversation_message_broadcast)).to eq(conversation_message_broadcast) }
  end

  describe "PUT #update" do
    let!(:conversation_message_broadcast) { FactoryGirl.create(:conversation_message_broadcast, goal: 'offer_help') }

    context "common field" do
      before {
        put :update, id: conversation_message_broadcast.id, conversation_message_broadcast: { goal: 'ask_for_help' }
        conversation_message_broadcast.reload
      }
      it { expect(conversation_message_broadcast.goal).to eq('ask_for_help')}
    end

    context "archive" do
      before {
        put :update, id: conversation_message_broadcast.id, :archive => true, conversation_message_broadcast: { goal: 'ask_for_help' }
        conversation_message_broadcast.reload
      }
      it { expect(conversation_message_broadcast.status).to eq('archived') }
      it { expect(conversation_message_broadcast.archived_at).to be_a_kind_of(Time) }
    end
  end

  describe "PUT #clone" do
    let!(:conversation_message_broadcast) { FactoryGirl.create(:conversation_message_broadcast, title: 'Broadcast to be cloned') }
    before { put :clone, id: conversation_message_broadcast.id }
    it {
      expect(assigns(:conversation_message_broadcast)).not_to eq(conversation_message_broadcast)
      expect(assigns(:conversation_message_broadcast).title).to eq('Broadcast to be cloned')
      expect(assigns(:conversation_message_broadcast).id).to eq(nil)
    }
  end

  describe "POST #broadcast" do
    let!(:conversation_message_broadcast) { FactoryGirl.create(:conversation_message_broadcast) }
    it {
      expect(ConversationMessageBroadcastJob).to receive(:perform_later)
      post :broadcast, id: conversation_message_broadcast.id
    }
  end
end
