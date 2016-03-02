require 'rails_helper'

RSpec.describe Api::V1::UserApplicationsController, type: :controller do

  describe "PUT #update" do
    context "user not signed in" do
      before { put :update, user_application: {push_token: "foobar", device_os: "ios", version: "1.1"} }
      it { expect(response.status).to eq 401 }
    end

    context "user signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }

      context "new application" do
        before { put :update, user_application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(response.status).to eq 204 }
        it { expect(user.user_applications.count).to eq(1) }
        it { expect(user.user_applications.first.push_token).to eq("foobar") }
      end

      context "application already exist" do
        let!(:ios_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "ios", version: "1.1") }
        before { put :update, user_application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(response.status).to eq 204 }
        it { expect(user.user_applications.count).to eq(1) }
        it { expect(user.user_applications.first.push_token).to eq("foobar") }
      end

      context "another application exists" do
        let!(:android_user_application) { FactoryGirl.create(:user_application, user: user, push_token: "old_token", device_os: "android", version: "1.1") }
        before { put :update, user_application: {push_token: "foobar", device_os: "ios", version: "1.1"}, token: user.token }
        it { expect(response.status).to eq 204 }
        it { expect(user.user_applications.count).to eq(2) }
        it { expect(user.user_applications.where(device_os: "ios").first.push_token).to eq("foobar") }
      end
    end
  end
end
