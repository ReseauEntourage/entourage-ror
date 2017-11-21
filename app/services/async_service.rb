class AsyncService
  def initialize klass
    @klass = klass
  end

  def method_missing(symbol, *args)
    if handled_method?(symbol)
      AsyncServiceJob.perform_later @klass.name, symbol.to_s, *args
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_all)
    handled_method?(symbol) || super
  end

  private

  def handled_method? symbol
    @klass.respond_to? symbol
  end
end
