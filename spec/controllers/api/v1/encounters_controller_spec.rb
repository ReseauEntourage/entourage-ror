require 'rails_helper'

RSpec.describe Api::V1::EncountersController, :type => :controller do
  render_views

  describe "POST create with tour" do
    let!(:user) { FactoryGirl.create :user }
    let!(:tour) { FactoryGirl.create :tour, user: user }
    let!(:encounter) { FactoryGirl.build :encounter, tour: tour }

    describe "response" do
      before { post 'create', tour_id: tour.id, token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json }

      it { expect(response.status).to eq(201) }
      it { expect(Encounter.last.tour).to eq(tour) }

      it "renders encounter" do
        resp = JSON.parse(response.body)
        encounter = Encounter.last
        expect(resp).to eq({"encounter"=>{"id"=>encounter.id, "date"=>"2014-10-11T15:19:45.000+02:00", "latitude"=>48.870424, "longitude"=>2.3068194999999605, "user_id"=>encounter.tour.user.id, "user_name"=>"John", "street_person_name"=>"Toto", "message"=>"Toto fait du velo.", "voice_message"=>"https://www.google.com"}})
      end
    end

    describe "jobs" do
      it "reverse geocode encounter" do
        expect(EncounterReverseGeocodeJob).to receive(:perform_later)
        post 'create', tour_id: tour.id, token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json
      end
    end
  end
end
