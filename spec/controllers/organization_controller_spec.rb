require 'rails_helper'
include AuthHelper

RSpec.describe OrganizationController, :type => :controller do
  context 'correct authentication' do
    let!(:user) { manager_basic_login }
    describe '#edit' do
      before { get :edit }
      it { should respond_with 200 }
    end
    describe '#update' do
      before { get :update, organization:{name: 'newname', description: 'newdescription', phone: 'newphone', address:'newaddress'} }
      it { expect(User.find(user.id).organization.name).to eq 'newname' }
      it { expect(User.find(user.id).organization.description).to eq 'newdescription' }
      it { expect(User.find(user.id).organization.phone).to eq 'newphone' }
      it { expect(User.find(user.id).organization.address).to eq 'newaddress' }
    end
  end
  context 'no authentication' do
    describe '#edit' do
      before { get :edit }
      it { should respond_with 401 }
    end
    describe '#update' do
      before { patch :update }
      it { should respond_with 401 }
    end
  end
end