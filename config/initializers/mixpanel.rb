require 'batch_processing_thread'

Rails.application.configure do
  config.mixpanel_thread = BatchProcessingThread::Client.new(batch_size: Mixpanel::BufferedConsumer::MAX_LENGTH) do |batch|
    buffered_consumer =
      if ENV['MIXPANEL_TOKEN']
        Mixpanel::BufferedConsumer.new
      else
        Mixpanel::BufferedConsumer.new do |type, message|
          Rails.logger.debug "type=mixpanel.mock.#{type} message=#{message}"
        end
      end
    begin
      batch.each do |type, message|
        buffered_consumer.send!(type, message)
      end
      buffered_consumer.flush
    rescue Mixpanel::MixpanelError => e
      Rails.logger.error "type=mixpanel.error class=#{e.class} message=#{e.message.inspect}"
    end
  end

  config.mixpanel = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN']) do |type, message|
    config.mixpanel_thread.enqueue(type, message)
  end
end
