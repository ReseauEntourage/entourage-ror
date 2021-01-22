require 'tasks/airtable'

namespace :airtable do
  task :export, [:channel, :dpts, :stade] => :environment do |t, args|
    channel = args[:channel]
    dpts = args[:dpts]
    stade = args[:stade]

    unless channel && dpts && stade
      raise 'Missing arguments; task should define: channel, dpts, stade'
    end

    Airtable.upload channel, dpts.split(' '), stade
  end
end
