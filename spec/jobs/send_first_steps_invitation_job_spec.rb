require 'rails_helper'

RSpec.describe SendFirstStepsInvitationJob do
  let(:user) { create :public_user }
  let!(:first_steps_outing) {
    create(:outing, :outing_class, online: true, sf_category: :welcome_entourage_local)
  }

  subject { described_class.new.perform(user.id) }

  it 'sends a first_steps_invitation email' do
    expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'when user does not exist' do
    subject { described_class.new.perform(0) }

    it 'does nothing' do
      expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end

  context 'when user is already registered to a first steps session' do
    before {
      create(:join_request, joinable: first_steps_outing, user: user, status: JoinRequest::ACCEPTED_STATUS)
    }

    it 'does not send the email' do
      expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
