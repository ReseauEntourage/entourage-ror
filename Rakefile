# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

require 'dredd/rack'
Dredd::Rack.app = Rails.application

Dredd::Rack::RakeTask.new(:dredd) do |task|
  task.runner.configure do |dredd|
    dredd.paths_to_blueprints './*.apib', 'blueprints/*.apib'
    dredd.hookfiles './dredd/hooks/add_basic_auth.js'
    dredd.sorted!
  end
end