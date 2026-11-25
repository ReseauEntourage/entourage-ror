module Assistant
  # The calls that Local makes for the AI assistant carry personal data (the text of a place, the
  # identifier of an account) or a secret (X-Service-Key). The global Sentry breadcrumbs of the app
  # (config/initializers/geocoder.rb and sentry.rb) record the options and the answer of every call: they
  # check `suppressed?` and record nothing while a block runs inside `suppressed`.
  module Breadcrumbs
    FLAG = :assistant_without_breadcrumbs

    module_function

    def suppressed?
      Thread.current[FLAG] == true
    end

    def suppressed
      previous = Thread.current[FLAG]
      Thread.current[FLAG] = true
      yield
    ensure
      Thread.current[FLAG] = previous
    end
  end
end
