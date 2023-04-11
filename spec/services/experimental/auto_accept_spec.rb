require 'rails_helper'

describe Experimental::AutoAccept do
  let(:entourage) { create :entourage, :joined }
  let(:user) { create :public_user }
  let(:join_request) { build :join_request, joinable: entourage, user: user }
  let!(:moderator) { create :admin_user }

  before do
    Experimental::AutoAccept.stub(:enable_callback) { true }
  end

  context "when the entourage owner is Équipe Entourage" do
    let(:entourage) { create :entourage, :joined, user: moderator }

    it do
      expect(entourage.auto_accept_join_requests?).to be true
    end
  end

  context "when the entourage owner is not Équipe Entourage" do
    before { entourage.user.stub(:email) { 'bob@burgers.com' } }

    it do
      expect(entourage.auto_accept_join_requests?).to be false
    end
  end

  context "when the entourage has auto-accept enabled" do
    before { entourage.stub(:auto_accept_join_requests?) { true } }

    it do
      expect(Experimental::AutoAccept).to receive(:accept).with(join_request).and_call_original
      join_request.save!
    end

    it do
      join_request.save!
      expect(join_request.reload.status).to eq 'accepted'
    end

    context "when updating the status of an existing request to pending" do
      let(:join_request) { create :join_request, status: :cancelled, joinable: entourage, user: user }

      it do
        expect(Experimental::AutoAccept).to receive(:accept).with(join_request).and_call_original
        join_request.update!(status: :pending)
      end
    end
  end

  context "when the entourage has auto-accept disabled" do
    before { entourage.stub(:auto_accept_join_requests?) { false } }

    it do
      expect(Experimental::AutoAccept).not_to receive(:accept)
      join_request.save!
    end

    it do
      join_request.save!
      expect(join_request.reload.status).to eq 'pending'
    end
  end
end
