require 'rails_helper'
include AuthHelper

describe Admin::UserMessageBroadcastsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    context 'has user_message_broadcasts' do
      let!(:user_message_broadcast_list) { create_list(:user_message_broadcast, 2) }
      before { get :index }

      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array(user_message_broadcast_list.pluck(:id)) }
    end

    context 'has no user_message_broadcasts' do
      before { get :index }
      it { expect(assigns(:user_message_broadcasts)).to eq([]) }
    end
  end

  # filters
  describe 'GET #index goal filter' do
    let!(:ask_for_help) { create(:user_message_broadcast, goal: 'ask_for_help') }
    let!(:offer_help) { create(:user_message_broadcast, goal: 'offer_help') }

    context 'has goal user_message_broadcasts' do
      before { get :index, params: { goal: 'ask_for_help' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([ask_for_help].pluck(:id)) }
    end

    context 'has goal user_message_broadcasts' do
      before { get :index, params: { goal: 'offer_help' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([offer_help].pluck(:id)) }
    end
  end

  describe 'GET #index area filter' do
    let!(:dep_75) { create(:user_message_broadcast, area_type: 'list', areas: ['75']) }
    let!(:hors_zone) { create(:user_message_broadcast, area_type: 'hors_zone') }

    context 'has area user_message_broadcasts' do
      before { get :index, params: { area: 'dep_75' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([dep_75].pluck(:id)) }
    end

    context 'has area user_message_broadcasts' do
      before { get :index, params: { area: 'hors_zone' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([hors_zone].pluck(:id)) }
    end
  end

  describe 'GET #index status filter' do
    let!(:sent) { create(:user_message_broadcast, status: 'sent') }
    let!(:archived) { create(:user_message_broadcast, status: 'archived', archived_at: Time.now) }

    context 'has default status user_message_broadcasts' do
      before { get :index }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([sent].pluck(:id)) }
    end

    context 'has status user_message_broadcasts' do
      before { get :index, params: { status: 'sent' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([sent].pluck(:id)) }
    end

    context 'has status user_message_broadcasts' do
      before { get :index, params: { status: 'archived' } }
      it { expect(assigns(:user_message_broadcasts).pluck(:id)).to match_array([archived].pluck(:id)) }
    end
  end

  describe 'GET #new' do
    before { get :new }
    it { expect(assigns(:user_message_broadcast)).to be_a_new(ConversationMessageBroadcast) }
  end

  describe 'POST #create' do
    context 'create success' do
      let(:user_message_broadcast) { post :create, params: { 'user_message_broadcast' => {
        area_type: 'list',
        areas: ['75'],
        content: 'Contenu du broadcast',
        goal: 'ask_for_help',
        title: 'Titre du broadcast'
      } } }
      it { expect { user_message_broadcast }.to change { ConversationMessageBroadcast.count }.by(1) }
    end

    context 'create failure' do
      let(:user_message_broadcast) { post :create, params: { 'user_message_broadcast' => {
        area: nil,
        content: 'Contenu du broadcast',
        goal: 'ask_for_help',
        title: 'Titre du broadcast'
      } } }
        it { expect { user_message_broadcast }.to change { ConversationMessageBroadcast.count }.by(0) }
    end
  end

  describe 'GET #edit' do
    let!(:user_message_broadcast) { create(:user_message_broadcast) }
    before { get :edit, params: { id: user_message_broadcast.to_param } }
    it { expect(assigns(:user_message_broadcast)).to eq(user_message_broadcast) }
  end

  describe 'PUT #update' do
    let!(:user_message_broadcast) { create(:user_message_broadcast, goal: 'offer_help') }

    context 'common field' do
      before {
        put :update, params: { id: user_message_broadcast.id, user_message_broadcast: { goal: 'ask_for_help' } }
        user_message_broadcast.reload
      }
      it { expect(user_message_broadcast.goal).to eq('ask_for_help')}
    end

    context 'archive' do
      before {
        put :update, params: { id: user_message_broadcast.id, archive: true, user_message_broadcast: { goal: 'ask_for_help' } }
        user_message_broadcast.reload
      }
      it { expect(user_message_broadcast.status).to eq('archived') }
      it { expect(user_message_broadcast.archived_at).to be_a_kind_of(Time) }
    end
  end

  describe 'PUT #clone' do
    let!(:user_message_broadcast) { create(:user_message_broadcast, title: 'Broadcast to be cloned') }
    before { put :clone, params: { id: user_message_broadcast.id } }
    it {
      expect(assigns(:user_message_broadcast)).not_to eq(user_message_broadcast)
      expect(assigns(:user_message_broadcast).title).to eq('Broadcast to be cloned')
      expect(assigns(:user_message_broadcast).id).to eq(nil)
    }
  end

  describe 'POST #broadcast' do
    let(:user_message_broadcast) { create(:user_message_broadcast, status: :draft) }

    describe 'single sending' do
      before { ConversationMessageBroadcast.any_instance.stub(:sending?).and_return(false) }

      it {
        expect(ConversationMessageBroadcastJob).to receive(:perform_later).once

        post :broadcast, params: { id: user_message_broadcast.id }
      }
    end

    describe 'double sending' do
      before { ConversationMessageBroadcast.any_instance.stub(:sending?).and_return(false) }

      it {
        expect(ConversationMessageBroadcastJob).to receive(:perform_later).once

        post :broadcast, params: { id: user_message_broadcast.id }
        post :broadcast, params: { id: user_message_broadcast.id }
      }
    end
  end
end
