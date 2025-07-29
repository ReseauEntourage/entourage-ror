require 'rails_helper'

describe MailjetController do
  describe 'POST event' do
    subject { post :event, params: { _json: [event] } }

    let(:user) { create :public_user }
    let(:category) { create :email_category }

    context "'unsub'" do
      let(:event) { {event: :unsub, email: user.email, Payload: {unsubscribe_category: category.name}.to_json} }

      it 'unsubscribes the user from that category' do
        expect { subject }
        .to change { EmailPreferencesService.accepts_emails?(user: user, category: category.name) }
        .to(false)
      end

      it { expect(response.code).to eq '200' }
    end
  end
end
