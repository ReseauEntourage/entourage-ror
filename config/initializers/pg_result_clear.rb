# The pg gem used to connect to PostgreSQL currently has a bug that can cause
# memory bloat.
#
# It is fixed in the upcoming pg v1.1.0 for Ruby 2.4+:
# https://github.com/ged/ruby-pg/pull/23
#
# Note that only rails 5.x supports pg 1.x.
#
# Until then, when using a method that returns a raw PG::Result such as
# `ActiveRecord::Base.connection.execute`, call explicitly the `.clear` on the
# object after using it.
#
# See:
# https://samsaffron.com/archive/2018/06/13/ruby-x27-s-external-malloc-problem
# https://github.com/rails/rails/issues/22331
# https://deveiate.org/code/pg/PG/Result.html

raise if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.4') &&
         Gem::Version.new(PG::VERSION)  >= Gem::Version.new('1.1')
