require 'rails_helper'

describe Facebook::FacebookAuthenticator do
  describe 'authenticate' do
    let(:facebook_user) {
      {
          "id"=>"123456789",
          "bio"=>"foo foo",
          "first_name"=>"Vincent",
          "gender"=>"male",
          "last_name"=>"Daubry",
          "email"=>"foo@bar.com",
          "link"=>"https://www.facebook.com/app_scoped_user_id/123456789/",
          "locale"=>"fr_FR",
          "name"=>"Vincent Daubry",
          "timezone"=>1,
          "updated_time"=>"2015-08-26T13:59:47+0000",
          "verified"=>true
      }
    }

    context "valid token" do
      let(:authenticator) { Facebook::FacebookAuthenticator.new(token: "foobar") }
      before(:each) do
        stub_request(:get, "https://graph.facebook.com/me?access_token=foobar").
            to_return(:status => 200, :body => "", :headers => {})

        Facebook::Client.any_instance.stub(:me) { facebook_user }
      end

      context "existing user" do
        let!(:existing_user) { FactoryGirl.create(:public_user) }
        let!(:authentication_provider) { FacebookAuthenticationProvider.create(user: existing_user, provider: "facebook", provider_id: facebook_user["id"]) }

        it { expect(authenticator.authenticate).to eq(existing_user) }

        it "doesn't create new user" do
          expect {
            authenticator.authenticate
          }.to change { User.count }.by(0)
        end

        it "doesn't create authentication provider" do
          expect {
            authenticator.authenticate
          }.to change { FacebookAuthenticationProvider.count }.by(0)
        end
      end
    end

    context "invalid token" do
      let(:authenticator) { Facebook::FacebookAuthenticator.new(token: "foobar") }
      before { Facebook::Client.any_instance.stub(:me).and_raise(Facebook::InvalidTokenError) }
      it { expect(authenticator.authenticate).to be nil }
    end
  end

  describe 'authenticate with existing user' do
    let(:facebook_user) {
      {
          "id"=>"123456789",
          "bio"=>"foo foo",
          "first_name"=>"Vincent",
          "gender"=>"male",
          "last_name"=>"Daubry",
          "email"=>nil,
          "link"=>"https://www.facebook.com/app_scoped_user_id/123456789/",
          "locale"=>"fr_FR",
          "name"=>"Vincent Daubry",
          "timezone"=>1,
          "updated_time"=>"2015-08-26T13:59:47+0000",
          "verified"=>true
      }
    }

    let(:authenticator) { Facebook::FacebookAuthenticator.new(token: "foobar") }
    before(:each) do
      stub_request(:get, "https://graph.facebook.com/me?access_token=foobar").
          to_return(:status => 200, :body => "", :headers => {})

      Facebook::Client.any_instance.stub(:me) { facebook_user }
    end

    context "existing user" do
      let!(:existing_user) { FactoryGirl.create(:public_user, email: "testfoo@bar.com", admin: true) }
      let!(:authentication_provider) { FacebookAuthenticationProvider.create(user: existing_user, provider: "facebook", provider_id: facebook_user["id"]) }
      before { authenticator.authenticate }
      it { expect(existing_user.reload.email).to eq("testfoo@bar.com") }
      it { expect(existing_user.reload.admin).to be true }
    end
  end
end
