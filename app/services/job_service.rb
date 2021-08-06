require 'sidekiq/api'

module JobService
  def self.retries
    # @why retrie? because retry seems a protected word
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
      JSON.parse(process.value)
    end
  end

  def self.workers
    Sidekiq::Workers.new.map do |worker|
      JSON.parse(worker.value)
    end
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
