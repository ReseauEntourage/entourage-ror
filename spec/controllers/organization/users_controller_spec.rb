require 'rails_helper'
include AuthHelper

RSpec.describe Organization::UsersController, :type => :controller do
  render_views
  
  context 'correct authentication' do
    let!(:user) { manager_basic_login }
    describe '#index' do
      before { get :index }
      it { should respond_with 200 }
      it { expect(assigns[:new_user]).not_to be_nil }
    end
    describe '#edit' do
      context 'correct organization' do
        let!(:edited_user) { create :user, organization: user.organization }
        before { get :edit, id:edited_user.id }
        it { should respond_with 200 }
        it { expect(assigns[:user]).to eq edited_user }
      end
      context 'incorrect organization' do
        let!(:edited_user) { create :user }
        before { get :edit, id:edited_user.id }
        it { should respond_with 403 }
      end
      context 'unknown user' do
        before { get :edit, id:-1 }
        it { should respond_with 404 }
      end
    end
    describe '#create' do
      let!(:new_user) { build :user }
      context 'utilisateur valide' do
        before { post :create, user:{ first_name:new_user.first_name, last_name:new_user.last_name, phone:new_user.phone, email:new_user.email, manager:new_user.manager } }
        it { should redirect_to action: :index }
        it { expect(User.last.first_name).to eq new_user.first_name }
        it { expect(User.last.last_name).to eq new_user.last_name }
        it { expect(User.last.phone).to eq new_user.phone }
        it { expect(User.last.email).to eq new_user.email }
        it { expect(User.last.manager).to eq new_user.manager }
        it { expect(User.last.organization).to eq user.organization }
        it { expect(flash[:notice]).to eq "L'utilisateur a été créé" }
      end
      context 'utilisateur invalide' do
        before { post :create, user:{ first_name:new_user.first_name, last_name:new_user.last_name, phone:'invalid phone', email:new_user.email, manager:new_user.manager } }
        it { should redirect_to action: :index }
        it { expect(flash[:notice]).to eq "Erreur de création" }
      end
    end
    describe '#update' do
      context 'correct organization' do
        let!(:updated_user) { create :user, organization: user.organization }
        context 'utilisateur valide' do
          before { patch :update, id:updated_user.id, user:{ first_name:'newfn', last_name:'newln', phone:'+33999999999', email:'n@ew.e', manager:!updated_user.manager } }
          it { should redirect_to action: :index }
          it { expect(User.find(updated_user.id).first_name).to eq 'newfn' }
          it { expect(User.find(updated_user.id).last_name).to eq 'newln' }
          it { expect(User.find(updated_user.id).phone).to eq '+33999999999' }
          it { expect(User.find(updated_user.id).email).to eq 'n@ew.e' }
          it { expect(User.find(updated_user.id).manager).to eq !updated_user.manager }
          it { expect(flash[:notice]).to eq "L'utilisateur a été sauvegardé" }
        end
        context 'utilisateur invalide' do
          before { patch :update, id:updated_user.id, user:{ first_name:'newfn', last_name:'newln', phone:'invalid phone', email:'invalid email', manager:!updated_user.manager } }
          it { should respond_with 200 }
          it { expect(flash[:notice]).to eq "Erreur de modification" }
        end
      end
      context 'incorrect organization' do
        let!(:updated_user) { create :user }
        before { patch :update, id:updated_user.id, user:{ first_name:'newfn', last_name:'newln', phone:'+33999999999', email:'n@ew.e', manager:!updated_user.manager } }
        it { should respond_with 403 }
      end
      context 'unknown user' do
        before { patch :update, id:-1, user:{ first_name:'newfn', last_name:'newln', phone:'invalid phone', email:'invalid email', manager:true } }
        it { should respond_with 404 }
      end
    end
    describe '#destroy' do
      context 'correct organization' do
        let!(:deleted_user) { create :user, organization: user.organization }
        before { delete :destroy, id:deleted_user.id }
        it { should redirect_to action: :index }
        it { expect(flash[:notice]).to eq "L'utilisateur a bien été supprimé" }
        it { expect(User.exists?(deleted_user.id)).to be false }
      end
      context 'incorrect organization' do
        let!(:deleted_user) { create :user }
        before { delete :destroy, id:deleted_user.id }
        it { should respond_with 403 }
      end
      context 'unknown user' do
        before { delete :destroy, id:-1 }
        it { should respond_with 404 }
      end
    end
    describe '#send_sms' do
      let!(:sms_notification_service) { spy('sms_notification_service') }
      context 'the user exists and is the same organization' do
        let(:sms_user) { create :user, organization: user.organization }
        let(:url_shortener) { spy('url_shortener') }
        let(:link) { 'link' }
        before do
          controller.sms_notification_service = sms_notification_service
          allow(url_shortener).to receive(:shorten).and_return(link)
          controller.url_shortener = url_shortener
          post 'send_sms', id: sms_user.id, format: :json
        end
        it { expect(response.status).to eq(200) }
        it { expect(sms_notification_service).to have_received(:send_notification).with(sms_user.phone, "Bienvenue sur Entourage. Votre code est #{sms_user.sms_code}. Retrouvez l'application ici : #{link} .") }
      end
      context 'the user exists but different organizations' do
        let(:sms_user) { FactoryGirl.create :user }
        before do
          controller.sms_notification_service = sms_notification_service
          post 'send_sms', id: sms_user.id, format: :json
        end
        it { expect(response.status).to eq(403) }
      end
      context 'the user does not exists' do
        before do
          controller.sms_notification_service = sms_notification_service
          post 'send_sms', id: -1, format: :json
        end
        it { expect(response.status).to eq(404) }
      end
    end
  end
  context 'no authentication' do
    describe '#index' do
      before { get :index }
      it { should respond_with 302 }
    end
    describe '#edit' do
      before { get :edit, id:1 }
      it { should respond_with 302 }
    end
    describe '#create' do
      before { post :create, user: {} }
      it { should respond_with 302 }
    end
    describe '#update' do
      before { patch :update, id:1, user: {} }
      it { should respond_with 302 }
    end
    describe '#destroy' do
      before { get :destroy, id:1 }
      it { should respond_with 302 }
    end
    describe '#send_sms' do
      before { post :send_sms, id:1 }
      it { should respond_with 302 }
    end
  end
end