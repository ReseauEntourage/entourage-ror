require 'sidekiq/api'

module JobMetricService
  def self.retries
    # @why retrie? because retry is a protected word
    Sidekiq::RetrySet.new.map do |retrie|
      JSON.parse(retrie.value)
    end
  end

  def self.deads
    Sidekiq::DeadSet.new.map do |dead|
      JSON.parse(dead.value)
    end
  end

  def self.schedules
    Sidekiq::ScheduledSet.new.map do |schedule|
      JSON.parse(schedule.value)
    end
  end

  def self.processes
    Sidekiq::ProcessSet.new.map do |process|
      {
        hostname: process['hostname'],
        started_at: process['started_at'],
        identity: process['identity'],
        busy: process['busy'],
        pid: process['pid'],
      }
    end
  end

  def self.workers
    Sidekiq::Workers.new.map do |process_id, thread_id, work|
      {
        process_id: process_id,
        thread_id: thread_id,
        work: work,
        queue: work['payload']['queue'],
        class: work['payload']['class'],
        args: work['payload']['args'],
        created_at: work['payload']['created_at'],
        enqueued_at: work['payload']['enqueued_at'],
        run_at: work['enqueued_at'],
      }
    end
  end

  def self.queues
    list = []

    Sidekiq::Queue.all.each do |queue|
      queue.each do |job|
        list << {
          queue: queue.name,
          size: queue.size,
          klass: job.klass,
          args: job.args
        }
      end
    end

    list
  end

  def self.stats
    stat = Sidekiq::Stats.new

    {
      processed: stat.processed,
      failed: stat.failed,
      queues: stat.queues,
      enqueued: stat.enqueued,
    }
  end

  def self.history days
    stat = Sidekiq::Stats::History.new(days)

    {
      processed: stat.processed,
      failed: stat.failed,
    }
  end
end
