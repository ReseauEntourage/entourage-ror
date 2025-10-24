module DailyTaskHelper
  module_function
  def at_day n, options={}, &block
    UserSegmentService.at_day(n, options).find_each do |record|
      begin
        yield record
      rescue => e
        Rails.logger.error(e)
      end
    end
  end
end
