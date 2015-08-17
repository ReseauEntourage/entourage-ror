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
      let!(:edited_user) { create :user }
      before { get :edit, id:edited_user.id }
      it { should respond_with 200 }
      it { expect(assigns[:user]).to eq edited_user }
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
      let!(:updated_user) { create :user }
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
    describe '#destroy' do
      let!(:deleted_user) { create :user }
      before { delete :destroy, id:deleted_user.id }
      it { should redirect_to action: :index }
      it { expect(flash[:notice]).to eq "L'utilisateur a bien été supprimé" }
      it { expect(User.exists?(deleted_user.id)).to be false }
    end
  end
  context 'no authentication' do
    describe '#index' do
      before { get :index }
      it { should respond_with 401 }
    end
    describe '#edit' do
      before { get :edit, id:1 }
      it { should respond_with 401 }
    end
    describe '#create' do
      before { post :create, user: {} }
      it { should respond_with 401 }
    end
    describe '#update' do
      before { patch :update, id:1, user: {} }
      it { should respond_with 401 }
    end
    describe '#destroy' do
      before { get :destroy, id:1 }
      it { should respond_with 401 }
    end
  end
end