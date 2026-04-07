require 'rails_helper'

describe MailjetController do
  let(:user) { create :public_user }
  let(:category) { create :email_category }
  let(:payload) { { unsubscribe_category: category.name }.to_json }

  describe 'POST event' do
    subject { post :event, params: params }

    let(:event) { { event: :unsub, email: user.email } }

    context "unsub list" do
      let(:params) { { _json: [event.merge(Payload: payload)] } }

      it { expect { subject }.to change {
        EmailPreferencesService.accepts_emails?(user: user, category: category.name)
      }.to(false) }

      it { expect(response.code).to eq("200") }
    end

    context "unsub" do
      let(:params) { event.merge(Payload: payload) }

      it { expect { subject }.to change {
        EmailPreferencesService.accepts_emails?(user: user, category: category.name)
      }.to(false) }

      it { expect(response.code).to eq("200") }
    end
  end
end
