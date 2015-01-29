require 'rails_helper'

RSpec.describe EncountersController, :type => :controller do

  describe "POST create" do

      let!(:user) { FactoryGirl.create :user }
      let!(:encounter) { FactoryGirl.build :valid_encounter }

      it "creates new encounter" do
        post 'create', token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
        expect(response).to be_success
      end

  end

end
