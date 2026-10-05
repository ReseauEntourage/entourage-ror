require 'rails_helper'
require 'rake'

describe 'user_stats:backfill' do
  before(:all) do
    Rake.application.rake_require('tasks/user_stats', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['user_stats:backfill'] }
  let(:user) { create(:public_user) }
  let(:neighborhood) { create(:neighborhood) }

  before do
    create(:entourage, user: user)
    create(:chat_message, messageable: neighborhood, user: user)
    # jobs run inline in specs: start the backfill from an empty table
    UserStat.delete_all
    task.reenable

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('BATCH_SIZE').and_return('1')
    allow(ENV).to receive(:[]).with('FROM_ID').and_return(nil)
  end

  it 'backfills every batch up to the last user' do
    expect { task.invoke }.to output(/user_stats:backfill users/).to_stdout

    expect(user.reload.user_stat).to have_attributes(action_creations_count: 1, neighborhood_messages_count: 1)
  end
end
