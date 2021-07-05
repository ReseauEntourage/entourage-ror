require 'rails_helper'
include AuthHelper

describe Admin::UsersSearchController do
  let!(:searched) { FactoryBot.create(:public_user, first_name: 'Youri', last_name: 'Gagarine', email: 'youri@gagarine.social', phone: '+33600000000') }

  describe 'GET user_search authentication' do
    context "not signed in" do
      before { get :user_search }
      it { should redirect_to new_session_path(continue: request.fullpath) }
    end

    context "signed in" do
      let!(:user) { admin_basic_login }
      before { get :user_search }
      it { expect(response.code).to eq("200") }
    end

  end

  describe 'GET user_search authentication' do
    let!(:user) { admin_basic_login }

    # found
    context "like first_name" do
      before { get :user_search, params: { search: 'Youri'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context "like last_name" do
      before { get :user_search, params: { search: 'Gagarine'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context "like email" do
      before { get :user_search, params: { search: 'youri@gagarine'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    context "like full_name" do
      before { get :user_search, params: { search: 'Youri Gagarine'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context "exact phone" do
      before { get :user_search, params: { search: '+33600000000'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    # case insensitive
    context "like first_name case insensitive" do
      before { get :user_search, params: { search: 'YOURI'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context "like last_name case insensitive" do
      before { get :user_search, params: { search: 'GAGARINE'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context "like email case insensitive" do
      before { get :user_search, params: { search: 'YOURI@GAGARINE'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    # strip insensitive
    context "like first_name strip insensitive" do
      before { get :user_search, params: { search: '  youri  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:first_name).uniq).to eq([searched.first_name]) }
    end

    context "like last_name strip insensitive" do
      before { get :user_search, params: { search: '  gagarine  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:last_name).uniq).to eq([searched.last_name]) }
    end

    context "like email strip insensitive" do
      before { get :user_search, params: { search: '  youri@gagarine  '} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:email).uniq).to eq([searched.email]) }
    end

    # phone formats
    context "phone with no country code" do
      before { get :user_search, params: { search: '0600000000'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    context "phone with spaces and no country code" do
      before { get :user_search, params: { search: '06 00 00 00 00'} }
      it { expect(assigns(:users).count).to eq(1) }
      it { expect(assigns(:users).map(&:phone).uniq).to eq([searched.phone]) }
    end

    # not found
    context "not like first_name" do
      before { get :user_search, params: { search: 'Marie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context "not like last_name" do
      before { get :user_search, params: { search: 'Curie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context "not like email" do
      before { get :user_search, params: { search: 'marie@curie'} }
      it { expect(assigns(:users).count).to eq(0) }
    end

    context "different phone" do
      before { get :user_search, params: { search: '+33700000000'} }
      it { expect(assigns(:users).count).to eq(0) }
    end
  end
end
