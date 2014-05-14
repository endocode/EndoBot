require 'daemons'

require_relative 'botconfig'
require_relative 'botgone'
require_relative 'botlistener'
require_relative 'botlog'
require_relative 'botloguser'
require_relative 'botpid'
require_relative 'endochilibot'
require_relative 'endoreportbot'

# Main class of Endobot daemon, reads configuration, sets up listener,
# notifier, signal handlers and bots.
class BotDaemon

  include BotLogUser

  def initialize(ini_path)
    @ini_path = ini_path
  end

  def run
    begin
      daemonize
      setup_config
      setup_logger
      setup_gone_notifier
      setup_listener
      setup_bots

      if bots_available?
        run_listener
        setup_signals
        setup_pidfile
        wait
      else
        log.error('No bots are running, quitting.')
      end
    rescue => ex
      handle_exception(ex)
    end

    cleanup_pidfile
    exit 0
  end

  def daemonize
    Daemonize.daemonize(nil, 'endobot')
  end

  def setup_config
    @config = BotConfig.new(@ini_path)
  end

  def setup_logger
    log_path = @config.get_log_path
    log_level = @config.get_log_level
    @logger = BotLog.new(log_path, log_level)
    self.log = @logger
  end

  def setup_gone_notifier
    @gone_notifier = BotGone.new
    @gone_notifier.log = @logger
  end

  def setup_listener
    listener_read_pipe = @gone_notifier.get_new_pipe
    @listener = BotListener.new(listener_read_pipe, @config)
    @listener.log = @logger
  end

  def setup_bots
    @bot_threads = []
    bot_class_list.each do |bot_class|
      bot_instance = bot_class.new
      bot_instance.log = @logger
      can_use, errors = bot_instance.can_use_config(@config)
      if can_use
        log.info("Running #{bot_class.to_s} instance.")
        bot_instance.config = @config
        bot_instance.queue = @listener.get_new_bot_queue(bot_class)

        @bot_threads << Thread.new do
          begin
            bot_instance.run
            log.info("#{bot_class} thread finishing, notifying.")
            @gone_notifier.notify(bot_class)
          rescue => ex
            handle_exception(ex)
          end
        end
      else
        log.info("Not running #{bot_class.to_s} instance - no valid configuration.")
        log.info_array("Configuration errors for #{bot_class.to_s}:", errors)
      end
    end
  end

  def bot_class_list
    [EndoReportBot, EndoChiliBot]
  end

  def bots_available?
    @bot_threads.size > 0
  end

  def run_listener
    log.info('Setting up listener.')
    @listener_thread = Thread.new do
      begin
        @listener.run
        log.info('Listener thread finishing.')
      rescue => ex
        handle_exception(ex)
        log.error('Listener death is fatal, killing bots.')
        @bot_threads.each { |bot_thread| bot_thread.kill }
      end
    end
  end

  def setup_signals
    Signal.trap('TERM') do
      log.info('Got TERM, requesting bots to quit.')
      gone_notifier.notify_force_all_bots_to_quit
    end
  end

  def setup_pidfile
    log.info('Setting up pidfile.')
    @pidfile = BotPid.new(@config.get_pid_directory)
    @pidfile.create
  end

  def wait
    log.info('Waiting for bots to quit.')
    @bot_threads.each { |thread| thread.join }
    log.info('Waiting for listener to quit.')
    @listener_thread.join
    log.info('Bots and listener quitted. Shutting down daemon.')
  end

  def handle_exception(ex)
    unless log.nil?
      log.error("Exception caught: #{ex}.")
      log.backtrace(ex.backtrace)
    end
  end

  def cleanup_pidfile
    unless @pidfile.nil?
      log.info('Removing pidfile.')
      @pidfile.delete
    end
  end

end
