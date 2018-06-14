class AsyncServiceJob < ActiveJob::Base
  queue_as :default

  def perform(klass, symbol, *args)
    Module.const_get(klass).send symbol, *args
  end
end
