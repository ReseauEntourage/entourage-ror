require 'rails_helper'

RSpec.describe TourServices::JoinRequestStatus do
  let(:owner) { FactoryBot.create(:public_user) }
  let(:requester) { FactoryBot.create(:public_user, first_name: "foo", last_name: "bar") }
  let(:entourage) { FactoryBot.create(:entourage, user: owner) }
  let!(:join_request) { JoinRequest.create(user: requester, joinable: entourage, status: "pending") }

  subject { TourServices::JoinRequestStatus.new(join_request: join_request) }

  before { ENV["QUIT_ENTOURAGE_NOTIFICATION"]="true" }
  after { ENV["QUIT_ENTOURAGE_NOTIFICATION"]="false" }

  describe 'reject!' do
    it {
      expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("Foo B.",
        "Demande annulée",
        "Demande annulée",
        [owner],
        {
          joinable_id: entourage.id,
          joinable_type: entourage.class.name,
          group_type: 'action',
          type: "JOIN_REQUEST_CANCELED",
          user_id: requester.id,
          instance: "conversations",
          id: entourage.id
        }
      )
    }

    after { subject.reject! }
  end

  describe 'quit!' do
    it {
      expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("Foo B.",
        "Demande annulée",
        "Demande annulée",
        [owner],
        {
          joinable_id: entourage.id,
          joinable_type: entourage.class.name,
          group_type: 'action',
          type: "JOIN_REQUEST_CANCELED",
          user_id: requester.id,
          instance: "conversations",
          id: entourage.id
        }
      )
    }

    after { subject.quit! }
  end
end
