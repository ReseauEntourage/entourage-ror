class AsyncService
  def initialize klass
    @klass = klass
    @job = AsyncServiceJob
  end

  def method_missing(symbol, *args)
    if active_job_method?(symbol)
      @job = @job.send symbol, *args
      self
    elsif handled_method?(symbol)
      @job.perform_later @klass.name, symbol.to_s, *args
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

  def active_job_method? symbol
    [:set].include? symbol
  end
end
