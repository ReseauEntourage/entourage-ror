require 'rails_helper'

RSpec.describe EncountersController, :type => :controller do
  render_views

  describe "POST create with tour" do
      let!(:user) { FactoryGirl.create :user }
      let!(:tour) { FactoryGirl.create :tour, user: user }
      let!(:encounter) { FactoryGirl.build :encounter, tour: tour }

      before { post 'create', tour_id: tour.id, token: user.token , encounter: {street_person_name: encounter.street_person_name, date: encounter.date, latitude: encounter.latitude, longitude: encounter.longitude, message: encounter.message, voice_message: encounter.voice_message_url }, :format => :json }
      
      it { should respond_with 201 }
      it { expect(Encounter.last.tour).to eq(tour) }
  end
end
