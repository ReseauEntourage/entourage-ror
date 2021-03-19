require 'rails_helper'

RSpec.describe EntourageDenorm, type: :model do
  describe "after_create update entourage" do
    let(:entourage) { create :entourage }
    let(:chat_message) { create :chat_message, messageable: entourage }

    it do
      denorm = EntourageDenorm.find_by(entourage_id: chat_message.messageable_id)

      expect(denorm).to be_kind_of EntourageDenorm
      expect(denorm.max_chat_message_created_at).to be_kind_of Time
      expect(denorm.max_chat_message_created_at.change(usec: 0)).to eq(chat_message.created_at.change(usec: 0))
    end
  end

  describe "after_save join_request" do
    let(:entourage) { create :entourage }

    describe "no requested_at for accepted" do
      let(:join_request) { create :join_request, joinable: entourage, status: 'accepted', message: 'message' }

      # requested_at should be nil
      it do
        expect(join_request.requested_at).to eq nil
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at
        ).to eq nil
      end
    end

    describe "requested_at for pending" do
      let(:join_request) { create :join_request, joinable: entourage, status: 'pending', message: 'message' }

      it do
      # requested_at should be a date
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end

    describe "no requested_at for pending with nil message" do
      let(:join_request) { create :join_request, joinable: entourage, status: 'pending', message: nil }

      it do
      # requested_at should be a date but max_join_request_requested_at should be nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at
        ).to eq nil
      end
    end

    describe "from accepted to pending" do
      let(:join_request) { create :join_request, joinable: entourage, status: 'accepted', message: 'message' }

      # requested_at should change from nil to date
      it do
        join_request.update_attribute(:status, 'pending')
        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end

    describe "from pending to accepted" do
      let!(:join_request_past) { create :join_request, joinable: entourage, status: 'pending', message: 'message', requested_at: 6.hours.ago }
      let(:join_request)       { create :join_request, joinable: entourage, status: 'pending', message: 'message' }

      # requested_at should not change but stays a date
      it do
        join_request.update_attribute(:status, 'accepted')
        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))
      end
    end

    describe "from pending to rejected" do
      let!(:join_request_past) { create :join_request, joinable: entourage, status: 'pending', message: 'message', requested_at: 6.hours.ago }
      let!(:join_request)      { create :join_request, joinable: entourage, status: 'pending', message: 'message' }

      it do
        # prerequisite
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request.requested_at.change(usec: 0))

        join_request.update_attribute(:status, 'rejected')

        expect(join_request.requested_at).not_to eq nil
        expect(join_request.requested_at).to be_kind_of Time
        # max_join_request_requested_at changed to join_request_past.requested_at
        expect(
          EntourageDenorm.find_by(entourage_id: join_request.joinable_id).max_join_request_requested_at.change(usec: 0)
        ).to eq(join_request_past.requested_at.change(usec: 0))
      end
    end
  end
end