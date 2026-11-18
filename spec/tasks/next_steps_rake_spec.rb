require 'rails_helper'
require 'rake'

describe 'next_steps:purge' do
  before(:all) do
    Rake.application.rake_require('tasks/next_steps', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['next_steps:purge'] }

  before { task.reenable }

  it 'deletes the history older than 6 months and reports what it deleted' do
    create(:next_step, status: 'expired', created_at: 7.months.ago)
    recent = create(:next_step, status: 'expired', created_at: 5.months.ago)

    expect { task.invoke }.to output(/next_steps:purge next_step_interactions=0 next_steps=1/).to_stdout

    expect(NextStep.all).to contain_exactly(recent)
  end
end
