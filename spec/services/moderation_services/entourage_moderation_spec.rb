require 'rails_helper'

describe ModerationServices::EntourageModeration do

  describe '#.on_create' do
    subject { described_class.on_create(entourage) }
    let(:entourage) { create :entourage, updated_at: 10.hours.ago }

    context 'when admin exists' do
      let!(:admin) { create :admin_user }

      it 'should change number_of_people by 1' do
        expect { subject }.to change { entourage.reload.number_of_people }.by(1)
      end

      let(:admin_join_request) { entourage.join_requests.find_by(user: admin) }
      it 'should add the admin to the group' do
        subject
        expect(admin_join_request&.status).to eq 'accepted'
      end
    end
  end

end