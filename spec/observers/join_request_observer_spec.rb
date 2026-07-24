require 'rails_helper'

describe JoinRequestObserver do
  describe 'mailer' do
    let(:join_request) { create :join_request, joinable: joinable }

    context 'outing membership does trigger mailer' do
      let(:joinable) { create(:outing) }

      before { expect_any_instance_of(GroupMailer).to receive(:event_joined_confirmation) }

      it { join_request }
    end

    context 'neighborhood membership does not trigger mailer' do
      let(:joinable) { create(:neighborhood) }

      before { expect_any_instance_of(GroupMailer).not_to receive(:event_joined_confirmation) }

      it { join_request }
    end
  end

  describe 'stats' do
    it 'updates outings_count when an accepted join_request is created on an outing' do
      user = create(:public_user)
      outing = create(:outing)

      expect {
        create(:join_request, joinable: outing, user: user, status: JoinRequest::ACCEPTED_STATUS)
      }.to change { user.reload.outings_count }.from(0).to(1)
    end

    it 'updates neighborhoods_count when an accepted join_request is created on a neighborhood' do
      user = create(:public_user)
      neighborhood = create(:neighborhood)

      expect {
        create(:join_request, joinable: neighborhood, user: user, status: JoinRequest::ACCEPTED_STATUS)
      }.to change { user.reload.neighborhoods_count }.from(0).to(1)
    end

    it 'updates entourages_count and actions_count when creating an entourage' do
      user = create(:public_user)

      expect {
        create(:entourage, :joined, group_type: 'action', user: user)
      }.to change { user.reload.entourages_count }.from(0).to(1)
        .and change { user.reload.actions_count }.from(0).to(1)
    end

    it 'decrements the count back when the join_request is destroyed' do
      user = create(:public_user)
      outing = create(:outing)
      join_request = create(:join_request, joinable: outing, user: user, status: JoinRequest::ACCEPTED_STATUS)

      expect {
        join_request.destroy
      }.to change { user.reload.outings_count }.from(1).to(0)
    end

    it 'updates the count when a join_request status changes to accepted' do
      user = create(:public_user)
      outing = create(:outing)
      join_request = create(:join_request, joinable: outing, user: user, status: JoinRequest::PENDING_STATUS)

      expect {
        join_request.update(status: JoinRequest::ACCEPTED_STATUS)
      }.to change { user.reload.outings_count }.from(0).to(1)
    end
  end
end
