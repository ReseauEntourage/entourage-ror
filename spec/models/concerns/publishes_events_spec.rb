require 'rails_helper'

RSpec.describe PublishesEvents, type: :module do
  let(:user) { create(:public_user) }

  describe 'after_commit on create' do
    it 'publishes a created event' do
      received = nil
      EventBus.subscribe('join_request.created', ->(payload) { received = payload })

      outing = create(:outing)
      create(:join_request, user: user, joinable: outing, status: 'accepted')

      expect(received).not_to be_nil
      expect(received[:record]).to be_a(JoinRequest)
    end
  end

  describe 'after_commit on update' do
    it 'publishes an updated event' do
      received = nil
      outing = create(:outing)
      join_request = create(:join_request, user: user, joinable: outing, status: 'accepted')

      EventBus.subscribe('join_request.updated', ->(payload) { received = payload })

      join_request.touch

      expect(received).not_to be_nil
      expect(received[:record]).to eq(join_request)
    end
  end
end
