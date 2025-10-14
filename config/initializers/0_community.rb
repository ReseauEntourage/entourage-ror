require File.expand_path('../../community', __FILE__)

if Rails.env.in?(%w(development test))
  ENV['COMMUNITY'] ||= 'entourage'
end

raise 'Environment variable COMMUNITY must be set' if ENV['COMMUNITY'].blank?
$server_community = Community.new ENV['COMMUNITY']
