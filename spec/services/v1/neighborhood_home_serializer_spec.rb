require 'rails_helper'

describe V1::NeighborhoodHomeSerializer do
  let(:user) { create(:public_user) }
  let(:neighborhood) { create(:neighborhood) }
  let(:scope) { { user: user } }

  let!(:other_member) { create(:join_request, user: create(:public_user), joinable: neighborhood, status: :accepted, unread_messages_count: 5) }

  let(:serializer) { described_class.new(neighborhood, scope: scope) }

  describe 'member and unread_posts_count' do
    subject { [serializer.member, serializer.unread_posts_count] }

    context 'without user' do
      let(:scope) { {} }

      it { expect(subject).to eq([false, nil]) }
    end

    context 'not a member' do
      it { expect(subject).to eq([false, nil]) }
    end

    context 'pending join request' do
      before { create(:join_request, user: user, joinable: neighborhood, status: :pending, unread_messages_count: 3) }

      it { expect(subject).to eq([false, nil]) }
    end

    context 'member' do
      before { create(:join_request, user: user, joinable: neighborhood, status: :accepted, unread_messages_count: 3) }

      it { expect(subject).to eq([true, 3]) }
    end

    context 'member of another neighborhood' do
      before { create(:join_request, user: user, joinable: create(:neighborhood), status: :accepted, unread_messages_count: 3) }

      it { expect(subject).to eq([false, nil]) }
    end
  end

  describe 'does not load the members' do
    subject(:queries) do
      [].tap do |sqls|
        callback = lambda do |*, payload|
          sqls << payload[:sql] unless payload[:name].in?(['SCHEMA', 'TRANSACTION']) || payload[:cached]
        end

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          serializer.member
          serializer.unread_posts_count
        end
      end
    end

    before do
      create(:join_request, user: user, joinable: neighborhood, status: :accepted, unread_messages_count: 3)
      create_list(:join_request, 3, joinable: neighborhood, status: :accepted)
    end

    it 'reads the current user join request once' do
      expect(queries.size).to eq(1)
      expect(queries.first).to include('"join_requests"."user_id"')
      expect(queries.first).not_to include('"users"')
    end
  end
end
