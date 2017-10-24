# Generic thread-safe batched queue consumer adapted from
# https://github.com/segmentio/analytics-ruby/tree/2.2.3.pre
# - lib/segment/analytics/client.rb
# - lib/segment/analytics/worker.rb
module BatchProcessingThread
  MAX_QUEUE_SIZE = 10000

  class Client
    def initialize batch_size:, &block
      raise ArgumentError, "a block is expected" unless block_given?

      @queue = Queue.new
      @max_queue_size = MAX_QUEUE_SIZE
      @worker_mutex = Mutex.new
      @worker = Worker.new @queue, batch_size, &block

      at_exit { @worker_thread && @worker_thread[:should_exit] = true }
    end

    def flush
      while !@queue.empty? || @worker.is_requesting?
        ensure_worker_running
        sleep(0.1)
      end
    end

    def enqueue(*args)
      unless queue_full = @queue.length >= @max_queue_size
        ensure_worker_running
        @queue << args
      end
      !queue_full
    end

    private

    def ensure_worker_running
      return if worker_running?
      @worker_mutex.synchronize do
        return if worker_running?
        @worker_thread = Thread.new do
          @worker.run
        end
      end
    end

    def worker_running?
      @worker_thread && @worker_thread.alive?
    end
  end

  class Worker
    def initialize(queue, batch_size, &block)
      @queue = queue
      @batch_size = batch_size
      @batch = []
      @lock = Mutex.new
      @process_batch = block
    end

    def run
      until Thread.current[:should_exit]
        return if @queue.empty?

        @lock.synchronize do
          until @batch.length >= @batch_size || @queue.empty?
            @batch << @queue.pop
          end
        end

        begin
          @process_batch.call @batch
        rescue Exception => e
          Rails.logger.error "type=batch_processing_thread.error class=#{e.class} message=#{e.message.inspect}"
        end

        @lock.synchronize { @batch.clear }
      end
    end

    def is_requesting?
      @lock.synchronize { @batch.any? }
    end
  end
end
