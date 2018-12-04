require 'rails_helper'

describe MailjetController do
  describe 'POST event' do
    subject { post :event, _json: [event] }
    let(:user) { create :public_user }

    context "'unsub'" do
      let(:event) { {event: :unsub, email: user.email} }
      it "unsubscribes the user from all emails" do
        expect { subject }.to change { user.reload.accepts_emails }.to(false)
      end
      it { expect(response.code).to eq '200' }
    end
  end
end
