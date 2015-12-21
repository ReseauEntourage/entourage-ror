require 'rails_helper'
include AuthHelper

describe ApplicationController, :type => :controller do

  describe 'authenticate_user!' do
    let(:time) { Time.parse("10/10/2010").at_beginning_of_day }
    before { controller.stub(:redirect_to) {} }
    before { Timecop.freeze(time) }

    context "not logged in" do
      it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
    end

    context "logged in" do
      let!(:user) { user_basic_login }

      context "not logged in the last hour" do
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(1) }
      end

      context "logged in the last hour" do
        let!(:user) { user_basic_login }
        before { LoginHistory.create(user_id: user.id, connected_at: time+10.minutes) }
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
      end

      describe "dont check db if logged in redis" do
        let!(:user) { user_basic_login }
        before { $redis.set("log_history:user:#{user.id}", "1") }
        it { expect {controller.authenticate_user!}.to change {LoginHistory.count}.by(0) }
      end
    end
  end
end