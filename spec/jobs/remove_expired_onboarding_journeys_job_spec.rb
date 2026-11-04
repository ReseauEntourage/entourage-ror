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

  # scheduled daily from the Heroku Scheduler, see EN-9444
  it 'is run by the onboarding_sequence:remove_expired_journeys task' do
    require 'rake'

    unless Rake::Task.task_defined?('onboarding_sequence:remove_expired_journeys')
      Rake::Task.define_task(:environment)
      load Rails.root.join('lib/tasks/onboarding_sequence.rake')
    end

    expect(RemoveExpiredOnboardingJourneysJob).to receive(:perform_now)

    task = Rake::Task['onboarding_sequence:remove_expired_journeys']
    task.reenable
    task.invoke
  end
end
