require 'rails_helper'

describe Api::V1::AuthenticationProvidersController do

  let(:logged_user) { FactoryGirl.create(:public_user) }
  let(:parsed_response) { JSON.parse(response.body) }

  describe 'POST create' do
    context "valid facebook response" do
      let(:facebook_user) {
        {
            "id"=>"123456789",
            "bio"=>"foo foo",
            "first_name"=>"Vincent",
            "gender"=>"male",
            "last_name"=>"Daubry",
            "birthday"=>"01/02/1983",
            "email"=>"foo@bar.com",
            "link"=>"https://www.facebook.com/app_scoped_user_id/123456789/",
            "locale"=>"fr_FR",
            "location"=>{"id"=>"110774245616525", "name"=>"Paris, France"},
            "name"=>"Vincent Daubry",
            "timezone"=>1,
            "updated_time"=>"2015-08-26T13:59:47+0000",
            "verified"=>true
        }
      }

      before(:each) do
        stub_request(:get, "https://graph.facebook.com/me?access_token=foobar&fields=id,email,first_name,last_name").
            to_return(:status => 200, :body => "", :headers => {})

        Facebook::Client.any_instance.stub(:me) { facebook_user }
      end

      context "valid token" do

        describe "Sign in user" do
          let!(:authentication_provider) { FacebookAuthenticationProvider.create(user: logged_user, provider: "facebook", provider_id: facebook_user["id"]) }
          before { post :create, user_id: logged_user.id, authentification_provider: {source: "facebook", token: "foobar"} }
          it { expect(parsed_response).to eq({"user" =>
                                                  {"id"=>logged_user.id,
                                                   "email"=>logged_user.email,
                                                   "token"=>logged_user.reload.token,
                                                   "first_name"=>"John",
                                                   "last_name"=>"Doe",
                                                   "display_name"=>"John Doe",
                                                   "avatar_url"=>nil,
                                                   "user_type"=>"public",
                                                   "organization"=>nil,
                                                   "stats"=>{"tour_count"=>0, "encounter_count"=>0}
                                                  }}) }
          it { expect(response.status).to eq(200) }
          it { expect(User.count).to eq(1) }
        end
      end

      context "invalid token" do
        let(:authenticator) { Facebook::FacebookAuthenticator.new(token: "foobar") }
        before { Facebook::Client.any_instance.stub(:me).and_raise(Facebook::InvalidTokenError) }
        before { post :create, user_id: logged_user.id, authentification_provider: {source: "facebook", token: "foobar"} }
        it { expect(response.status).to eq(401) }
        it { expect(parsed_response).to eq({"message"=>"Invalid Facebook token : foobar"}) }
      end
    end

    context "facebook error response" do
      let(:facebook_error) { {"error"=>{"message"=>"(#4) Application request limit reached", "type"=>"OAuthException", "is_transient"=>true, "code"=>4, "fbtrace_id"=>"BgGP7UYJrOV"}} }

      before(:each) do
        stub_request(:get, "https://graph.facebook.com/me?access_token=foobar&fields=id,email,first_name,last_name,gender,location,birthday").
            to_return(:status => 200, :body => facebook_error.to_json, :headers => {})
      end

      before { post :create, user_id: logged_user.id, authentification_provider: {source: "facebook", token: "foobar"} }
      it { expect(response.status).to eq(401) }
      it { expect(parsed_response).to eq({"message"=>"Facebook error : (#4) Application request limit reached"})}
    end
  end
end