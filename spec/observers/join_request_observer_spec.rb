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
end
