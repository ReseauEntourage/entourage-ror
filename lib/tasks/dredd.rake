namespace :dredd do
  desc 'Creates init data for dredd tests'
  task seeds: :environment do
    filename = File.join(Rails.root, 'db', 'seeds', 'dredd.rb')
    load(filename) if File.exist?(filename)
  end
end
