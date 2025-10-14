require 'rails_helper'
include AuthHelper

describe ApplicationController, type: :controller do
  render_views

  describe 'authenticate_user!' do
    let(:time) { Time.parse('10/10/2010').at_beginning_of_day }
    before { controller.stub(:redirect_to) {} }
    before { Timecop.freeze(time) }

    context 'not logged in' do
      it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
    end

    context 'logged in' do
      let!(:user) { user_basic_login }

      context 'not logged in the last hour' do
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(1) }
      end

      context 'logged in the last hour' do
        let!(:user) { user_basic_login }
        before { LoginHistory.create(user_id: user.id, connected_at: time+10.minutes) }
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
      end

      describe 'dont check db if logged in redis' do
        let!(:user) { user_basic_login }
        before { $redis.set("log_history:user:#{user.id}", '1') }
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
      end
    end
  end

  describe 'authorisations' do
    let(:admin) { FactoryBot.create(:pro_user, admin: true) }
    let(:manager) { FactoryBot.create(:pro_user, manager: true) }
    let(:user) { FactoryBot.create(:pro_user) }

    context 'admin' do
      before { session[:admin_user_id] = admin.id }
      before { session[:user_id] = admin.id }
      it { expect(controller.current_admin).to eq(admin) }
      it { expect(controller.current_manager).to eq(admin) }
      it { expect(controller.current_user).to eq(admin) }
    end

    context 'manager' do
      before { session[:user_id] = manager.id }
      it { expect(controller.current_admin).to be nil }
      it { expect(controller.current_manager).to eq(manager) }
      it { expect(controller.current_user).to eq(manager) }
    end

    context 'user' do
      before { session[:user_id] = user.id }
      it { expect(controller.current_admin).to be nil }
      it { expect(controller.current_manager).to be nil }
      it { expect(controller.current_user).to eq(user) }
    end

    context 'not logged in' do
      it { expect(controller.current_admin).to be nil }
      it { expect(controller.current_manager).to be nil }
      it { expect(controller.current_user).to be nil }
    end
  end

  describe 'ping_db' do
    before { get :ping_db }

    it { expect(response.status).to eq 200 }
    it { expect(JSON.parse(response.body)).to have_key 'count' }
  end
end
