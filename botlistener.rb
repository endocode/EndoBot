require 'socket'

require_relative 'botloguser'

# Listens for commands sent via a socket from external and via a pipe
# from BotGone. After getting a command it dispatches them to bots via
# queues.
class BotListener

  include BotLogUser

  def initialize(read_pipe, config)
    @queues = {}
    @read_pipe = read_pipe
    @path = config.get_socket_path
    @keep_going = true
    @config = config
  end

  def get_new_bot_queue(bot_class)
    bot_queue = Queue.new
    @queues[bot_class] = bot_queue
    bot_queue
  end

  def run
    if FileTest.exists?(@path)
      File.delete(@path)
    end
    UNIXServer.open(@path) do |server|
      while @keep_going
        cmd = self.get_command(server).strip
        unless cmd.empty?
          case cmd
          when 'reload'
            self.reload
          when 'stop'
            self.stop
          else
            log.info("Ignoring unknown command: #{cmd}.")
          end
        end
      end
    end
  end

  def get_command(server)
    cmd = ''
    begin
      s = server.accept_nonblock
      # we rather expect getting commands like stop, reload, so 10
      # bytes are enough
      cmd = s.gets(10)
      s.close
    rescue IO::WaitReadable, Errno::EINTR
      fds = IO.select([server, @read_pipe])
      log.debug("Listener got a readable descriptor.")
      rs = self.get_read_fd_from_fds(fds)
      if rs == @read_pipe
        cmd = handle_pipe_message
      elsif rs == server
        log.debug("Socket is possibly readable.")
        retry
      end
    end
    cmd
  end

  def get_read_fd_from_fds(fds)
    fd = nil
    unless fds.nil?
      readables = fds[0]
      fd = readables.first
    end
    fd
  end

  def handle_pipe_message
    cmd = ''
    log.debug('Pipe is readable.')
    a_class = BotGone.get_class_from_pipe(@read_pipe)
    if a_class == BotGone::ForceBotsToQuit
      cmd = 'stop'
    else
      log.debug("Bot #{a_class} is gone.")
      @queues.delete(a_class)
      if @queues.empty?
        log.debug("No bots running, stopping listener.")
        @keep_going = false
      end
    end
    cmd
  end

  def reload
    log.info('Reloading configuration.')
    @config.reload
    @queues.each_value { |q| q << 'reload' }
  end

  def stop
    log.info('Stopping daemon.')
    @queues.each_value { |q| q << 'stop' }
    @keep_going = false
  end

end
