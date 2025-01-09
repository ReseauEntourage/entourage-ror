require 'rails_helper'

RSpec.describe OutingRecurrence, type: :model do
  describe '.generate_all' do
    let(:current_time) { Time.now }
    let!(:valid_outing_recurrence) { create(:outing_recurrence, continue: true) }
    let!(:invalid_outing_recurrence) { create(:outing_recurrence, continue: true) }
    let!(:non_continuing_recurrence) { create(:outing_recurrence, continue: false) }

    let!(:valid_outing) do
      create(
        :outing,
        recurrency_identifier: valid_outing_recurrence.identifier,
        metadata: { starts_at: current_time + 1.hour, ends_at: current_time + 1.day },
        status: 'open'
      )
    end

    let!(:invalid_outing_past_date) do
      create(
        :outing,
        recurrency_identifier: invalid_outing_recurrence.identifier,
        metadata: { starts_at: current_time - 1.day, ends_at: current_time - 1.hour },
        status: 'open'
      )
    end

    let!(:invalid_outing_status) do
      create(
        :outing,
        recurrency_identifier: invalid_outing_recurrence.identifier,
        metadata: { starts_at: current_time + 1.hour, ends_at: current_time + 1.day },
        status: 'closed'
      )
    end

    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    it 'calls generate and save for valid outing recurrences' do
      allow_any_instance_of(OutingRecurrence).to receive(:generate).and_return(double(save: true))

      expect {
        OutingRecurrence.generate_all
      }.to change { OutingRecurrence.with_valid_outings.count }.by(0)
    end

    it 'does not process recurrences without valid outings' do
      allow_any_instance_of(OutingRecurrence).to receive(:generate).and_return(double(save: true))

      expect(OutingRecurrence.with_valid_outings).not_to include(invalid_outing_recurrence, non_continuing_recurrence)
    end
  end

  describe '.with_valid_outings' do
    let(:current_time) { Time.now }

    let!(:valid_outing_recurrence) { create(:outing_recurrence, continue: true) }
    let!(:valid_outing) do
      create(
        :outing,
        recurrency_identifier: valid_outing_recurrence.identifier,
        metadata: { starts_at: current_time + 1.hour, ends_at: current_time + 1.day },
        status: 'open'
      )
    end

    let!(:invalid_outing_recurrence) { create(:outing_recurrence, continue: true) }
    let!(:invalid_outing) do
      create(
        :outing,
        recurrency_identifier: invalid_outing_recurrence.identifier,
        metadata: { starts_at: current_time - 1.day, ends_at: current_time - 1.hour },
        status: 'open'
      )
    end

    let(:result) { OutingRecurrence.with_valid_outings.pluck(:id) }

    context 'returns only recurrences with valid outings' do
      it { expect(result).to include(valid_outing_recurrence.id) }
      it { expect(result).not_to include(invalid_outing_recurrence.id) }
    end

    context 'does not include recurrences with outings in the past' do
      it { expect(result).not_to include(invalid_outing_recurrence.id) }
    end

    context 'does not include recurrences with outings with invalid statuses' do
      let!(:invalid_status_outing) { create(:outing,
        recurrency_identifier: valid_outing_recurrence.identifier,
        metadata: { starts_at: current_time + 1.hour, ends_at: current_time + 1.day },
        status: 'closed'
      ) }

      it { expect(result).not_to include(invalid_status_outing.id) }
    end
  end
end
