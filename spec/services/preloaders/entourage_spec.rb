require 'rails_helper'

describe Preloaders::Entourage do
  describe '.preload_current_join_request' do
    let(:user) { create(:public_user) }

    it 'sets current_join_request to the user join_request on each entourage' do
      entourage = create(:entourage)
      join_request = create(:join_request, joinable: entourage, user: user)

      Preloaders::Entourage.preload_current_join_request([entourage], user: user)

      expect(entourage.current_join_request).to eq(join_request)
    end

    it 'sets current_join_request to nil when the user has no join_request on the entourage' do
      entourage = create(:entourage)

      Preloaders::Entourage.preload_current_join_request([entourage], user: user)

      expect(entourage.current_join_request).to be_nil
    end

    it 'does not mix up join_requests between entourages' do
      entourage_1 = create(:entourage)
      entourage_2 = create(:entourage)
      join_request_1 = create(:join_request, joinable: entourage_1, user: user)

      Preloaders::Entourage.preload_current_join_request([entourage_1, entourage_2], user: user)

      expect(entourage_1.current_join_request).to eq(join_request_1)
      expect(entourage_2.current_join_request).to be_nil
    end

    it 'ignores join_requests on other joinable types (e.g. Neighborhood)' do
      neighborhood = create(:neighborhood)
      entourage = create(:entourage)
      create(:join_request, joinable: neighborhood, user: user, status: JoinRequest::ACCEPTED_STATUS)

      Preloaders::Entourage.preload_current_join_request([entourage], user: user)

      expect(entourage.current_join_request).to be_nil
    end

    it 'does nothing when given an empty array' do
      expect { Preloaders::Entourage.preload_current_join_request([], user: user) }.not_to raise_error
    end
  end
end
