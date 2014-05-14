# A module designed to be a mixin. Implements log user.
module BotLogUser

  def log=(logger)
    @log = logger.personal_log(self.class)
  end

  def log
    @log
  end

end
