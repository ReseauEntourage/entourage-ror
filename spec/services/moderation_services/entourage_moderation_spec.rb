require 'rails_helper'

describe ModerationServices::EntourageModeration do

  describe '#.on_create' do
    subject { described_class.on_create(entourage) }
    let(:entourage) { create :entourage, updated_at: 10.hours.ago }

    context 'when admin exists' do
      let!(:admin) { create :admin_user }
      let(:admin_join_request) { entourage.join_requests.find_by(user: admin) }

      before { subject }

      it { expect(entourage.reload.number_of_people).to eq(1) }
      it { expect(admin_join_request&.status).to eq 'accepted' }
    end
  end

end
