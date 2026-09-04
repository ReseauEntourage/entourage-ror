require 'rails_helper'

describe EntourageServices::History do
  let(:entourage) { FactoryBot.create(:entourage, created_at: 3.days.ago) }
  let(:moderator) { FactoryBot.create(:pro_user) }

  subject { described_class.new(entourage).get }

  it 'includes the creation event' do
    expect(subject.first[:kind]).to eq(:creation)
    expect(subject.first[:date]).to eq(entourage.created_at)
  end

  context 'with a moderated entourage' do
    before do
      moderation = entourage.moderation || entourage.build_moderation
      moderation.update!(moderator: moderator, moderated_at: 2.days.ago, validated_at: 1.day.ago)
    end

    it 'includes moderation events in chronological order' do
      kinds = subject.map { |h| h[:kind] }
      expect(kinds).to eq([:creation, :moderated, :validated])
    end

    it 'attributes the moderation events to the moderator' do
      moderated_event = subject.find { |h| h[:kind] == :moderated }
      expect(moderated_event[:moderator]).to eq(moderator)
    end
  end

  context 'with an admin note' do
    let!(:note) { FactoryBot.create(:admin_note, notable: entourage, author: moderator, created_at: 1.hour.ago) }

    it 'includes the note as an event' do
      note_event = subject.find { |h| h[:kind] == :admin_note }
      expect(note_event[:metadata]).to eq(note.body)
      expect(note_event[:moderator]).to eq(moderator)
    end
  end
end
