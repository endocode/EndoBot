require 'daemons'

# Thin wrapper around Daemons::PidFile to avoid repeating magic
# strings on construction.
class BotPid

  def initialize(pid_dir)
    @pidfile = Daemons::PidFile.new(pid_dir, 'endobot')
  end

  def create
    @pidfile.pid = Process.pid
  end

  def exists?
    @pidfile.exist?
  end

  def delete
    @pidfile.cleanup
  end

  def pid
    @pidfile.pid
  end

end
