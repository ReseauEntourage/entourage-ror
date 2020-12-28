require 'rails_helper'
include AuthHelper

RSpec.describe ScheduledPushesController, type: :controller do
  render_views

  let(:service) { TourServices::SchedulePushService }
  before { Timecop.freeze(DateTime.parse("01/01/2016")) }

  describe 'GET index' do
    context "user not logged in" do
      before { get :index }
      it { should redirect_to new_session_path(continue: request.fullpath)  }
    end

    context "user logged in" do
      let!(:user) { user_basic_login }

      context "has push" do
        before { service.new(organization: user.organization, date: Date.parse("10/10/2016")).schedule(object: "foo1", message: "bar", sender: "me") }
        before { service.new(organization: user.organization, date: Date.parse("11/10/2016")).schedule(object: "foo2", message: "bar", sender: "me") }
        before { service.new(organization: user.organization, date: Date.parse("09/10/2016")).schedule(object: "foo3", message: "bar", sender: "me") }
        before { service.new(organization: FactoryBot.create(:organization), date: Date.parse("09/10/2016")).schedule(object: "foo3", message: "bar", sender: "me") }
        before { get :index }
        it { expect(assigns(:scheduled_pushes)).to eq([{"object"=>"foo3", "message"=>"bar", "sender"=>"me", "date"=>"2016-10-09"},
                                                       {"object"=>"foo1", "message"=>"bar", "sender"=>"me", "date"=>"2016-10-10"},
                                                       {"object"=>"foo2", "message"=>"bar", "sender"=>"me", "date"=>"2016-10-11"}]) }
      end

      context "no push" do
        before { get :index }
        it { expect(assigns(:scheduled_pushes)).to eq([]) }
      end
    end
  end

  describe 'DELETE destroy' do
    context "user not logged in" do
      before { delete :destroy, params: { date: "10/10/2016" } }
      it { should redirect_to new_session_path  }
    end

    context "user logged in" do
      let!(:user) { user_basic_login }
      before { service.new(organization: user.organization, date: Date.parse("10/10/2016")).schedule(object: "foo1", message: "bar", sender: "me") }
      before { service.new(organization: user.organization, date: Date.parse("11/10/2016")).schedule(object: "foo2", message: "bar", sender: "me") }
      before { delete :destroy, params: { date: "10/10/2016" } }
      it { expect(TourServices::SchedulePushService.all_scheduled_pushes(organization: user.organization)).to eq([{"object"=>"foo2", "message"=>"bar", "sender"=>"me", "date"=>"2016-10-11"}]) }
    end
  end
end
