require 'rails_helper'

RSpec.describe RemoveExpiredOnboardingJourneysJob do
  let!(:expired) { create(:public_user, created_at: 20.days.ago, first_sign_in_at: 20.days.ago) }
  let!(:running) { create(:public_user, created_at: 2.days.ago, first_sign_in_at: 2.days.ago) }

  subject { described_class.new.perform }

  it 'removes the journey of the members who did not come back' do
    expect { subject }.to change { Event.where(name: 'onboarding.parcours.removed').count }.by(1)

    expect(Event.find_by(user_id: expired.id, name: 'onboarding.parcours.removed').properties).to eq('reason' => 'inactivity')
    expect(Event.where(user_id: running.id, name: 'onboarding.parcours.removed')).to be_empty
  end

  it 'is scheduled daily' do
    schedule = YAML.safe_load(File.read(Rails.root.join('config/sidekiq.yml')), permitted_classes: [Symbol], aliases: true)

    job = schedule[:schedule]['remove_expired_onboarding_journeys']

    expect(job['class']).to eq('RemoveExpiredOnboardingJourneysJob')
    expect(job['cron']).to eq('30 3 * * *')
  end
end
