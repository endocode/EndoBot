require_relative 'botloguser'

# Class responsible for notifying listener about quitting bots, so it
# can stop listening. It also notifies listener about quitting the
# daemon, so listener can force bots to quit.
# The communication is done via a pipe - it is because pipes are
# selectable and they can be used in signal handlers.
class BotGone

  include BotLogUser

  class ForceBotsToQuit
  end

  def initialize
    @pipes = []
  end

  def get_new_pipe
    rd, wr = IO.pipe
    @pipes << wr
    rd
  end

  def notify(bot_class)
    log.debug("Notifying that #{bot_class} is gone.")
    self.notify_via_pipes(bot_class)
  end

  def notify_force_all_bots_to_quit
    log.debug("Notifying that all bots should be forced to quit.")
    self.notify_via_pipes(BotGone::ForceBotsToQuit)
  end

  def notify_via_pipes(a_class)
    @pipes.each do |pipe|
      begin
        BotGone.send_class_to_pipe(a_class, pipe)
      rescue => ex
        @pipes.delete(pipe)
        log.debug("Failed to notify disappearance of #{a_class} via a pipe: #{ex}.")
      end
    end
  end

  # Helper function to send a class over the pipe.
  def self.send_class_to_pipe(c, p)
    class_name = c.to_s
    p.write "#{class_name.length} #{class_name}"
  end

  # Helper function to get a class over the pipe.
  def self.get_class_from_pipe(p)
    num = p.gets(' ').strip.to_i
    str = p.gets(num)
    str_to_class(str)
  end

  def self.str_to_class(str)
    str.split('::').inject(Object) {|o,c| o.const_get c}
  end

end
