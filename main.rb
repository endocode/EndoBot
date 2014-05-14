require 'socket'

require_relative 'botconfig'
require_relative 'botdaemon'
require_relative 'botpid'

# Script for starting, stopping, restarting and reloading the Endobot
# daemon.

class BotManager

  class Error < RuntimeError
  end

  def initialize
    @cmd = ''
    @ini = '/etc/endobotconfig.ini'
    @allowed_cmds = ['start', 'stop', 'restart', 'reload', 'help']
  end

  def run(argv)
    args = argv.clone
    status = 0

    verify_args_size(args)
    get_cmd_and_ini_from_args(args)
    if help_wanted?
      help
    else
      load_config
      dispatch_command
    end

    status
  end

  def verify_args_size(args)
    if args.size == 0
      raise_with_help('Too few parameters.')
    end
  end

  def get_cmd_and_ini_from_args(args)
    @cmd = args.shift
    unless @allowed_cmds.include?(@cmd)
      raise_with_help("Wrong command: #{@cmd}")
    end
    if args.size > 0
      @ini = File.expand_path(args.shift)
    end
  end

  def help_wanted?
    @cmd == 'help'
  end

  def help
    puts get_help
  end

  def load_config
    config = BotConfig.new(@ini)
    @pidfile = BotPid.new(config.get_pid_directory)
    @sock_path = config.get_socket_path
  end

  def dispatch_command
    case @cmd
    when 'start'
      start
    when 'stop'
      stop
    when 'restart'
      stop
      start
    when 'reload'
      reload
    end
  end

  def start
    if @pidfile.exists?
      raise Error, 'Process already running'
    else
      daemon = BotDaemon.new(@ini)
      daemon.run
    end
  end

  def stop
    if @pidfile.exists?
      unless stop_with_command
        puts 'Could not stop the daemon with command, trying TERM'
        unless stop_with_sigterm
          puts 'Killing with KILL then'
          Process.kill('KILL', @pidfile.pid)
          @pidfile.delete
        end
      end
    else
      raise Error, 'No process'
    end
  end

  def stop_with_command
    begin
      issue_command('stop')
      counter = 5
      while @pidfile.exists? && counter > 0
        counter -= 1
        sleep(2)
      end
    rescue => ex
      puts "Could not stop the daemon with command: #{ex.message}"
    end
    !@pidfile.exists?
  end

  def stop_with_sigterm
    Process.kill('TERM', @pidfile.pid)
    sleep(10)
    !@pidfile.exists?
  end

  def reload
    if @pidfile.exists?
      issue_command('reload')
    else
      raise Error, 'No process'
    end
  end

  def issue_command(cmd)
    UNIXSocket.open(@sock_path) do |s|
      s.puts cmd
      s.close
    end
  end

  def raise_with_help(reason)
    raise Error, [reason, '', get_help].join("\n")
  end

  def get_help
    ["Usage: ruby #{$0} COMMAND [INI]",
     "COMMAND is one of following:",
     "#{@allowed_cmds.join(', ')}",
     "INI is optional parameter for giving a path to INI configuration.",
     "INI by default is #{@ini}"].join("\n")
  end

end

begin
  manager = BotManager.new
  manager.run(ARGV)
  exit 0
rescue BotManager::Error => ex
  puts ex.message
  exit 1
rescue => ex
  puts ex.message
  puts ex.backtrace
  exit 1
end
