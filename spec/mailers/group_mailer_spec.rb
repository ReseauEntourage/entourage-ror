require 'rails_helper'

describe GroupMailer, type: :mailer do
  let(:user) { create :public_user }
  let(:outing) { create :outing, user: user }

  describe ".event_joined_confirmation" do
    let(:user) { create :public_user }
    let(:mail) { GroupMailer.event_joined_confirmation(outing) }
    let(:json_variables) { JSON.parse(mail['X-MJ-Vars'].value) }

    it { expect(json_variables['first_name']).to eq(user.first_name) }
    it { expect(json_variables).to have_key("outing") }
    it { expect(json_variables['outing']['name']).to eq(outing.title) }
    it { expect(json_variables['outing']['calendar_url']).to match("agenda") }
  end
end
