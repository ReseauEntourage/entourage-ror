require 'rails_helper'

RSpec.describe EncountersController, :type => :controller do

  describe "POST create without tour" do

      let!(:user) { FactoryGirl.create :user }
      let!(:encounter) { FactoryGirl.build :valid_encounter }

      it "creates new encounter" do
        post 'create', token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
        expect(response.status).to eq(201)
      end

      it "is not related to any tour" do
        post 'create', token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
        last_encounter = Encounter.last
        expect(last_encounter.tour).to eq(nil)
      end
  end

  describe "POST create with tour" do

      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.create :tour }
      let!(:encounter) { FactoryGirl.build :valid_encounter }

      it "creates new encounter" do
        post 'create', tour_id: tour.id, token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
        expect(response.status).to eq(201)
      end

      it "is not related to any tour" do
        post 'create', tour_id: tour.id, token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
        last_encounter = Encounter.last
        expect(last_encounter.tour).to eq(tour)
      end
  end

end
