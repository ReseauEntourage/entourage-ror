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

  # regression test for a race condition where two concurrent processes
  # both saw entourage.moderation as blank and both tried to build+save one,
  # causing an unhandled PG::UniqueViolation on entourage_moderations.entourage_id
  describe 'moderation row created concurrently by another process' do
    let(:moderator) { create :user }

    before do
      # prevent the entourage's own after_commit callbacks from creating a
      # moderation row while we set up the fixture
      allow(described_class).to receive(:assign_to_area_moderator)
      allow(described_class).to receive(:assign_section)
    end

    let!(:entourage) { create :entourage, group_type: :action, country: 'FR', postal_code: '75001' }

    before do
      entourage.moderation # loads (and caches) the association as blank, no row exists yet
      create :entourage_moderation, entourage: entourage, moderator_id: nil # simulates the concurrent insert

      allow(described_class).to receive(:assign_to_area_moderator).and_call_original
      allow(described_class).to receive(:assign_section).and_call_original
      allow(ModerationServices).to receive(:moderator_for_entourage).and_return(moderator)
    end

    describe '.assign_to_area_moderator' do
      subject { described_class.assign_to_area_moderator(entourage) }

      it 'does not raise and updates the existing row instead of duplicating it' do
        expect { subject }.not_to raise_error
        expect(EntourageModeration.where(entourage_id: entourage.id).count).to eq(1)
        expect(entourage.reload.moderation.moderator_id).to eq(moderator.id)
      end
    end

    describe '.assign_section' do
      subject { described_class.assign_section(entourage) }

      it 'does not raise and updates the existing row instead of duplicating it' do
        expect { subject }.not_to raise_error
        expect(EntourageModeration.where(entourage_id: entourage.id).count).to eq(1)
        expect(entourage.reload.moderation.section).to be_present
      end
    end
  end

end
