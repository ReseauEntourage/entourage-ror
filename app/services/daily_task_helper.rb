module DailyTaskHelper
  module_function
  def at_day n, options={}, &block
    UserSegmentService.at_day(n, options).find_each do |record|
      begin
        yield record
      rescue => e
        Raven.capture_exception(
          e,
          extra: options.merge(
            at_day: n,
            record_class: record&.class,
            record_id: record&.id
          )
        )
      end
    end
  end
end
