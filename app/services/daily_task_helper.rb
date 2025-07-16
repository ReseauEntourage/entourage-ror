module DailyTaskHelper
  module_function
  def at_day n, options={}, &block
    UserSegmentService.at_day(n, options).find_each do |record|
      begin
        yield record
      rescue => e
        Sentry.capture_exception(e)
      end
    end
  end
end
