class AsyncServiceJob < ApplicationJob
  queue_as :default

  def perform(klass, symbol, *)
    Module.const_get(klass).send(symbol, *)
  end
end
