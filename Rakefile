# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

# The dredd-rack gem is only for dev
begin
  require 'dredd/rack'
  Dredd::Rack.app = Rails.application

  Dredd::Rack::RakeTask.new(:dredd) do |task|
    task.runner.configure do |dredd|
      dredd.paths_to_blueprints './*.apib', 'blueprints/*.apib'
      dredd.hookfiles './dredd/hooks/add_basic_auth.js'
      dredd.reporter(:junit).output('./dredd/output/report.xml')
      dredd.sorted!
    end
  end
rescue LoadError
end
