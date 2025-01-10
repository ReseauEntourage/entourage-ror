require 'rails_helper'

describe GroupMailer, type: :mailer do
  let(:participant) { create :public_user, first_name: 'Alice' }
  let(:organizer) { create :public_user, first_name: 'Bob' }
  let(:outing) { create :outing, user: organizer }

  describe ".event_joined_confirmation" do
    let(:mail) { GroupMailer.event_joined_confirmation(outing.id, participant.id) }
    let(:json_variables) { JSON.parse(mail['X-MJ-Vars'].value) }

    it { expect(json_variables['first_name']).to eq(participant.first_name) }
    it { expect(json_variables).to have_key("outing") }
    it { expect(json_variables['outing']['name']).to eq(outing.title) }
    it { expect(json_variables['outing']['calendar_url']).to match("agenda") }
  end
end
