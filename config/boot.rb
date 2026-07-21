ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Spring and Puma (preload_app!) have already bound sockets / set up their own process
# state by the time they require this file, and Ruby 3.2 has no RubyVM::YJIT.enable to
# turn YJIT on after the fact. Re-execing here would restart their whole boot sequence
# mid-flight (observed: Spring hangs forever, Puma double-boots) instead of just adding
# a flag. So under those we skip it; Puma/Sidekiq get YJIT via RUBYOPT in the Procfile
# instead, set before the process even starts. CI and plain `bundle exec` are unaffected.
if defined?(RubyVM::YJIT) && !RubyVM::YJIT.enabled? && !defined?(Spring) && !defined?(Puma) && ENV["DISABLE_YJIT"].nil?
  exec(ENV.to_h.merge("RUBYOPT" => [ENV["RUBYOPT"], "--yjit"].compact.join(" ")), RbConfig.ruby, $PROGRAM_NAME, *ARGV)
end

require "bundler/setup" # Set up gems listed in the Gemfile.
