#!/usr/bin/env ruby

require 'benchmark/ips'
require 'dotenv'

Dotenv.load
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])


def feeds_json(current_user)
  feeds = FeedServices::FeedFinder.new(user: current_user,
                                       page: 1,
                                       per: 25,
                                       latitude: 2.48,
                                       longitude: 49.5,
                                       show_tours: true,
                                       entourage_types: "ask_for_help,contribution",
                                       tour_types: "medical,barehands,alimentary",
                                       time_range: 365*24,
                                       show_my_entourages_only: false,
                                       show_my_tours_only: false).feeds
  ::V1::FeedSerializer.new(feeds: feeds, user: current_user).to_json
end



current_user = User.first
Benchmark.ips do |x|
  x.report("feed") do |times|
    feeds_json(current_user)
  end
end