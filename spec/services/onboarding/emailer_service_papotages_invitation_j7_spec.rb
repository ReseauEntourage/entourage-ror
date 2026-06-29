require 'rails_helper'

describe Onboarding::EmailerService, '.deliver_papotages_invitation_j7_email' do
  subject { described_class.deliver_papotages_invitation_j7_email }

  let!(:papotage_outing) {
    create(:outing, :outing_class, title: 'Papotage solidaire', online: true)
  }

  context 'user with first_sign_in_at exactly 7 days ago' do
    let!(:user) { create(:public_user, first_sign_in_at: 7.days.ago.noon) }

    it { expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1) }

    it 'does not send twice (deliver_only_once)' do
      subject
      expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end

  context 'user with first_sign_in_at less than 7 days ago' do
    let!(:user) { create(:public_user, first_sign_in_at: 3.days.ago) }

    it { expect { subject }.not_to change { ActionMailer::Base.deliveries.count } }
  end

  context 'user with first_sign_in_at more than 7 days ago' do
    let!(:user) { create(:public_user, first_sign_in_at: 10.days.ago) }

    it { expect { subject }.not_to change { ActionMailer::Base.deliveries.count } }
  end

  context 'user with no first_sign_in_at' do
    let!(:user) { create(:public_user, first_sign_in_at: nil) }

    it { expect { subject }.not_to change { ActionMailer::Base.deliveries.count } }
  end

  context 'user already registered to a future papotage' do
    let!(:user) { create(:public_user, first_sign_in_at: 7.days.ago.noon) }

    before {
      create(:join_request, joinable: papotage_outing, user: user, status: JoinRequest::ACCEPTED_STATUS)
    }

    it { expect { subject }.not_to change { ActionMailer::Base.deliveries.count } }
  end

  context 'user registered to a past papotage only' do
    let!(:user) { create(:public_user, first_sign_in_at: 7.days.ago.noon) }

    before {
      papotage_outing.update_columns(metadata: papotage_outing.metadata.merge(
        starts_at: 2.days.ago, ends_at: 1.day.ago
      ))
      create(:join_request, joinable: papotage_outing, user: user, status: JoinRequest::ACCEPTED_STATUS)
    }

    it { expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1) }
  end

  context 'deleted user' do
    let!(:user) { create(:public_user, first_sign_in_at: 7.days.ago.noon, deleted: true) }

    it { expect { subject }.not_to change { ActionMailer::Base.deliveries.count } }
  end
end
