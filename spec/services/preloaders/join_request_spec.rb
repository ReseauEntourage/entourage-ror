require 'rails_helper'

describe Preloaders::JoinRequest do
  describe '.preload_joinable' do
    it 'does nothing when given an empty array' do
      expect { Preloaders::JoinRequest.preload_joinable([]) }.not_to raise_error
    end

    it 'assigns each join_request its joinable, across polymorphic types' do
      user = create(:public_user)
      other = create(:public_user)
      conversation = create(:conversation, participants: [user, other])
      smalltalk = create(:smalltalk, participants: [user, other])
      neighborhood = create(:neighborhood, participants: [user])

      join_requests = user.accepted_join_requests.to_a
      Preloaders::JoinRequest.preload_joinable(join_requests)

      joinables_by_id = join_requests.index_by(&:joinable_id)
      expect(joinables_by_id[conversation.id].joinable).to eq(conversation)
      expect(joinables_by_id[smalltalk.id].joinable).to eq(smalltalk)
      expect(joinables_by_id[neighborhood.id].joinable).to eq(neighborhood)
    end

    it 'preloads accepted_members on Entourage joinables' do
      user = create(:public_user)
      other = create(:public_user)
      conversation = create(:conversation, participants: [user, other])

      join_requests = user.accepted_join_requests.to_a
      Preloaders::JoinRequest.preload_joinable(join_requests)

      join_request = join_requests.find { |jr| jr.joinable_id == conversation.id }
      expect(join_request.joinable.association(:accepted_members)).to be_loaded
    end

    it 'does not preload accepted_members on non-Entourage joinables' do
      user = create(:public_user)
      other = create(:public_user)
      smalltalk = create(:smalltalk, participants: [user, other])

      join_requests = user.accepted_join_requests.to_a
      Preloaders::JoinRequest.preload_joinable(join_requests)

      join_request = join_requests.find { |jr| jr.joinable_id == smalltalk.id }
      expect(join_request.joinable.association(:accepted_members)).not_to be_loaded
    end

    it 'avoids the users/join_requests N+1 query when resolving conversation interlocutors afterwards' do
      user = create(:public_user)
      other_1 = create(:public_user)
      other_2 = create(:public_user)
      conversation_1 = create(:conversation, participants: [user, other_1])
      conversation_2 = create(:conversation, participants: [user, other_2])

      join_requests = user.accepted_join_requests.to_a
      Preloaders::JoinRequest.preload_joinable(join_requests)

      queries = []
      callback = lambda do |*, payload|
        queries << payload[:sql] if payload[:sql] =~ /FROM "users" INNER JOIN "join_requests"/
      end

      interlocutors = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        join_requests.map { |join_request| join_request.joinable.interlocutor_of(user) }
      end

      expect(interlocutors).to match_array([other_1, other_2])
      expect(queries).to be_empty
    end
  end
end
