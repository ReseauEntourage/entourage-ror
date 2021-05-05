require 'rails_helper'

RSpec.describe Api::V1::EncountersController, :type => :controller do
  render_views

  let!(:user) { FactoryBot.create :pro_user }
  let!(:tour) { FactoryBot.create :tour, user: user }

  describe 'GET index' do
    context "valid params" do
      let!(:encounters) { FactoryBot.create_list(:encounter, 2, tour: tour) }
      before { get 'index', params: { tour_id: tour.to_param, token: user.token } }
      it { expect(JSON.parse(response.body)).to eq({"encounters"=>[{"id"=>encounters.first.id,
                                                                    "date"=>"2014-10-11T15:19:45.000+02:00",
                                                                    "latitude"=>48.870424,
                                                                    "longitude"=>2.306820,
                                                                    "user_id"=>user.id,
                                                                    "user_name"=>"John",
                                                                    "street_person_name"=>"Toto",
                                                                    "message"=>"Toto fait du velo.",
                                                                    "voice_message"=>"https://www.google.com"
                                                                   },
                                                                   {"id"=>encounters.last.id,
                                                                    "date"=>"2014-10-11T15:19:45.000+02:00",
                                                                    "latitude"=>48.870424,
                                                                    "longitude"=>2.306820,
                                                                    "user_id"=>user.id,
                                                                    "user_name"=>"John",
                                                                    "street_person_name"=>"Toto",
                                                                    "message"=>"Toto fait du velo.",
                                                                    "voice_message"=>"https://www.google.com"
                                                                   }]}) }
    end

    context "deleted encounter" do
      let!(:encounter) do
        encounter = FactoryBot.create(:encounter,
                                            tour: tour)
        encounter.update_columns(encrypted_message: nil,
                         street_person_name: nil,
                         latitude: nil,
                         longitude:nil,
                         address: nil)
        encounter
      end
      before { get 'index', params: { tour_id: tour.to_param, token: user.token } }
      it { expect(JSON.parse(response.body)).to eq({"encounters"=>[{"id"=>encounter.id,
                                                                    "date"=>"2014-10-11T15:19:45.000+02:00",
                                                                    "latitude"=>nil,
                                                                    "longitude"=>nil,
                                                                    "user_id"=>user.id,
                                                                    "user_name"=>"John",
                                                                    "street_person_name"=>"xxxx",
                                                                    "message"=>nil,
                                                                    "voice_message"=>"https://www.google.com"
                                                                   }]}) }
    end
  end

  describe "POST create" do
    let!(:encounter) { FactoryBot.build :encounter, tour: tour }

    describe "response" do
      before { post 'create', params: { tour_id: tour.id, token: user.token, encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json } }

      it { expect(response.status).to eq(201) }
      it { expect(Encounter.last.tour).to eq(tour) }

      it "renders encounter" do
        resp = JSON.parse(response.body)
        encounter = Encounter.last
        expect(resp).to eq({"encounter"=>{"id"=>encounter.id, "date"=>"2014-10-11T15:19:45.000+02:00", "latitude"=>48.870424, "longitude"=>2.30682, "user_id"=>encounter.tour.user.id, "user_name"=>"John", "street_person_name"=>"Toto", "message"=>"Toto fait du velo.", "voice_message"=>"https://www.google.com"}})
      end

      describe "create answers to encounter questions" do
        let(:question1) { FactoryBot.create(:question) }
        let(:question2) { FactoryBot.create(:question) }
        let(:encounter_params) {
          {street_person_name: encounter.street_person_name,
           date: encounter.date,
           latitude: encounter.latitude,
           longitude: encounter.longitude,
           message: encounter.message,
           voice_message: encounter.voice_message_url }
        }
        let(:answers_params) {
          [{question_id: question1.to_param, value: "foo"},
           {question_id: question2.to_param, value: "bar"}]
        }
        before { post 'create', params: { tour_id: tour.id, token: user.token, encounter: encounter_params, answers: answers_params, format: :json } }
        it { expect(Encounter.last.answers.count).to eq(2) }
      end
    end

    describe "jobs" do
      it "reverse geocode encounter" do
        expect(EncounterReverseGeocodeJob).to receive(:perform_later)
        post 'create', params: { tour_id: tour.id, token: user.token, encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json }
      end
    end
  end

  describe "PUT update" do
    let(:encounter) { FactoryBot.create(:encounter, street_person_name: "foo", message: "foobar", voice_message: "http://foo.bar") }
    before { put :update, params: { id: encounter.to_param, encounter: {street_person_name: "foo1", message: "foobar1", voice_message: "http://foo.bar1", longitude: 43.423, latitude: 1.674}, token: user.token } }
    let(:reloaded_encounter) { encounter.reload }
    it { expect(reloaded_encounter.street_person_name).to eq("foo1") }
    it { expect(reloaded_encounter.message).to eq("foobar1") }
    it { expect(reloaded_encounter.voice_message).to eq("http://foo.bar1") }
    it { expect(reloaded_encounter.latitude).to eq(1.674) }
    it { expect(reloaded_encounter.longitude).to eq(43.423) }
  end
end
