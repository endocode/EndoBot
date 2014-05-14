# A logger. It is not used directly, but rather each object gets a
# dedicated logger (see BotLog::PersonalLog). For convenience, use
# also a BotLogUser module.
#
# The output is generally in following form:
# "<timestamp> <severity> - <owner>: <message>"
#
# It might be possible that the log file is going to have mangled
# lines as the logger is used in several threads. No synchronisation
# is done because we want logger to be usable in signal handlers. This
# excludes using mutexes.
class BotLog

  class PersonalLog

    def initialize(log, owner_class)
      @log = log
      @owner = owner_class
    end

    def debug(msg)
      @log.log(:DEBUG, @owner, msg)
    end

    def info(msg)
      @log.log(:INFO, @owner, msg)
    end

    def warn(msg)
      @log.log(:WARN, @owner, msg)
    end

    def error(msg)
      @log.log(:ERROR, @owner, msg)
    end

    def info_array(header, lines)
      spaced_lines = lines.clone
      spaces = ' ' * @log.entry_header(:INFO, @owner).length
      spaced_lines.each do |entry|
        entry.strip!
        unless entry.empty?
          entry.prepend(spaces)
        end
      end
      msg = spaced_lines.unshift(header).join("\n")
      self.info(msg)
    end

    def backtrace(bt)
      self.info_array('Backtrace follows:', bt)
    end

  end

  def initialize(log_path, log_level)
    @log_file = File.open(log_path, 'a')
    @log_file.puts("==========")
    @log_file.puts("#{DateTime.now}: Opened this log file for appending.")
    @log_file.puts("==========")
    @levels = [:DEBUG, :INFO, :WARN, :ERROR]
    real_log_level = @levels.include?(log_level) ? log_level : :INFO
    @log_level = @levels.index(real_log_level)
  end

  def personal_log(owner)
    BotLog::PersonalLog.new(self, owner)
  end

  def log(type, owner, msg)
    if @log_level <= @levels.index(type)
      header = entry_header(type, owner)
      entry = "#{header}#{msg}"
      @log_file.puts(entry)
      @log_file.flush
    end
  end

  def entry_header(type, owner)
    "#{DateTime.now} #{type} - #{owner}: "
  end

end
