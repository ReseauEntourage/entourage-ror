#!/usr/bin/env ruby

if ARGV.count != 2
  $stderr.puts "Usage: #{$SCRIPT_NAME} <url> <secret>"
  $stderr.puts "  To fetch the secret from Heroku, use:"
  $stderr.puts "  $ heroku config:get ENTOURAGE_SECRET --app <app-name>"
  exit 1
end

require 'uri'
require 'cgi'
require 'base64'
require 'openssl'

url = ARGV[0]
secret = ARGV[1]

def signature url, secret
  url = URI(url)
  without_params = url.dup.tap { |u| u.query = nil }.to_s
  params_keys = CGI.parse(url.query).keys.sort
  definition = [without_params, *params_keys].map { |str| Base64.strict_encode64(str) }.join(',')
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, definition)[0...6]
end

def double_escape url
  2.times { url = CGI.escape url }
  url
end

puts "https://api.entourage.social/redirect/#{signature(url, secret)}/#{double_escape(url)}"
