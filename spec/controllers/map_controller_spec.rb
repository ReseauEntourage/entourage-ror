require 'rails_helper'

RSpec.describe MapController, :type => :controller do

  describe "GET index" do
    let!(:user) { create :user }

    it "returns http success if user is logged in" do
      get 'index', token: user.token, :format => :json
      expect(response).to be_success
    end

    it "returns an error if user is not logged in" do
      get 'index', :format => :json
      expect(response).not_to be_success
    end
  end

end
