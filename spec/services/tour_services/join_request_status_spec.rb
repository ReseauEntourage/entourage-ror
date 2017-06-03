require 'rails_helper'

RSpec.describe TourServices::JoinRequestStatus do

  let(:owner) { FactoryGirl.create(:public_user) }
  let(:requester) { FactoryGirl.create(:public_user, first_name: "foo", last_name: "bar") }
  let(:entourage) { FactoryGirl.create(:entourage, user: owner) }
  let!(:join_request) { JoinRequest.create(user: requester, joinable: entourage, status: "pending") }

  subject { TourServices::JoinRequestStatus.new(join_request: join_request) }

  describe 'reject!' do
    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("foo b",
                                                                                            "Demande annulée",
                                                                                            "Demande annulée",
                                                                                            [owner],
                                                                                            {
                                                                                                joinable_id: entourage.id,
                                                                                                joinable_type: entourage.class.name,
                                                                                                user_id: requester.id
                                                                                            }) }
    after { subject.reject! }
  end

  describe 'quit!' do
    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("foo b",
                                                                                             "Demande annulée",
                                                                                             "Demande annulée",
                                                                                             [owner],
                                                                                             {
                                                                                                 joinable_id: entourage.id,
                                                                                                 joinable_type: entourage.class.name,
                                                                                                 user_id: requester.id
                                                                                             }) }
    after { subject.quit! }
  end
end
