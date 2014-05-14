require 'rufus-scheduler'

# A subclass of Rufus::Scheduler to override error handler, so it
# prints caught exceptions into log file instead of STDERR.
class BotScheduler < Rufus::Scheduler

  def initialize(log)
    super({})
    @log = log
  end

  def on_error(job, error)
    @log.error("Caught an error inside scheduler: #{error.message}.")
    @log.backtrace(error.backtrace)
  end

end
