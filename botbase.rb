require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

require_relative 'botloguser'
require_relative 'botscheduler'

# A base class for a bot - it sets up jabber connection, provides a
# framework for handling messages and scheduling periodic events.
#
# In future it should also handle reconnecting in case of connection
# drops.
class BotBase

  include Jabber
  include BotLogUser

  public

  # Checks whether given +config+ can be used for this bot
  # implementation.
  #
  # Returns an array with two elements - first is boolean value
  # whether the config can be used, second is an array of errors.
  def can_use_config(config)
    errors = []
    can_use = false
    name = section_name
    if config.has_section?(name)
      section = config.get_section(name)
      can_use = true
      get_needed_keys.each do |key|
        unless section.has_key?(key)
          can_use = false
          errors << "No '#{key} key in '#{name}' section"
        end
      end
    else
      errors << "No '#{name}' section"
    end
    [can_use, errors]
  end

  # Sets given +config+ as new bot configuration. Assumes that
  # +config+ can be used (see can_use_config), otherwise result is
  # undefined.
  def config=(config)
    @config = config
    load_config_internal(@config)
  end

  # Sets a queue for getting messages from listener.
  def queue=(queue)
    @queue = queue
  end

  # Gets a nick for user if there is one. Otherwise it just returns
  # +user+.
  def get_nick_for_user(user)
    @user_mappings.fetch(user, user)
  end

  # Connects to jabber, sets up message handlers and scheduler. This
  # function blocks until bot quits.
  def run
    # Jabber::debug = true
    @client = Jabber::Client.new(@jid)
    @client.allow_tls = false
    @client.connect
    @client.auth(@password)
    @client.send(Presence.new.set_type(:available))

    @room = Jabber::MUC::SimpleMUCClient.new(@client)

    # SimpleMUCClient callback-blocks

    @room.on_message do |time, nick, text|
      log.debug("#{Date.today}, #{nick}, #{text}")
      handle_message(time, nick, text)
    end

    @room.join(@channel)

    @scheduler = BotScheduler.new(log)
    setup_scheduler(@scheduler)
    @scheduler.join

    @client.close
  end

  # Sends a private +message+ to +user+. +user+ shouldn't have any
  # domain in it, just a resource (that is - not "user@example.com",
  # but just "user").
  #
  # This function expects that +user+ and the bot are in the same
  # domain.
  def send_message_to_user(message, user)
    jabber_message = Message.new("#{user}@#{@jid.domain}", message)
    jabber_message.set_type(:chat).set_id('1')
    @client.send(jabber_message)
  end

  # Quits the bot.
  def exit(exit_message)
    log.info("Exiting.")
    @room.exit(exit_message)
    @scheduler.shutdown
    log.debug("Scheduler shutted down.")
  end

  # Sends a chat message to current room.
  def send_message_to_room(message)
    @room.say(message)
  end

  private # for overloading

  # General message handler. Returns true if message was
  # handled. Remember to chain up this function, so messages directed
  # to bot are also handled.
  def handle_message(time, nick, text)
    handled = false
    bot_query = bot_nick + ': '
    stripped_msg = text.strip

    if stripped_msg.start_with?(bot_query)
      message = stripped_msg.gsub(/^#{Regexp.escape(bot_query)}/, '')
      handled = handle_direct_message(time, nick, message)
    end

    handled
  end

  # Direct message handler. Returns true if message directed to bot
  # was handled. Remember to chain up this function, so certain direct
  # messages are also handled.
  def handle_direct_message(time, nick, message)
    handled = false
    if message == 'exit please'
      exit("Exiting on behalf of #{nick}.")
      handled = true
    end
    handled
  end

  # Sets up scheduler to fire some events. Remember to chain up this
  # function.
  def setup_scheduler(scheduler)
    scheduler.every '5s' do
      check_and_handle_queue_messages
    end
  end

  # Gets an array of keys that has to exist in configuration section
  # given by section_name. Remember to chain up this function, so some
  # default keys are added to the array as well.
  def get_needed_keys
    ['jid', 'password', 'channel']
  end

  # Gets a name of section that has to exist in configuration for bot
  # to work. No chaining up of this function. It throws a
  # NotImplementedError if subclass does not override it.
  def section_name
    raise NotImplementedError, "#{self.class} has no section_name implementation"
  end

  # Applies given +settings+. Remember to chain up this function, so
  # some default configuration values are applied.
  def apply_settings(settings)
    new_jid = Jabber::JID.new(settings['jid'])
    new_password = settings['password']
    new_channel = settings['channel']
    if running?
      settings = [[new_jid, @jid, 'jid'],
                  [new_password, @password, 'password'],
                  [new_channel, @channel, 'channel']]
      settings.each do |setting|
        new = setting[0]
        old = setting[1]
        key = setting[2]
        if (new != old)
          log.warn("Restart the daemon to apply '#{key}' change.")
        end
      end
    else
      @jid = new_jid
      @password = new_password
      @channel = new_channel
    end
  end

  # Apply a config. Usable when we need some values from outside the
  # bot specific section (see section_name). Remember to chain up this
  # function, so some values are applied too.
  def apply_config(config)
    @user_mappings = config.get_user_mappings
  end

  private # no overloading these, please

  def running?
    !(@scheduler.nil? || @scheduler.uptime.nil? || @room.nil? || @client.nil?)
  end

  def bot_nick
    @room.jid.resource
  end

  def check_and_handle_queue_messages
    until @queue.empty?
      handle_queue_message(@queue.pop)
    end
  end

  def handle_queue_message(message)
    case message
    when 'stop'
      self.exit("Exiting on behalf of some BOFH.")
    when 'reload'
      log.info("Reloading configuration.")
      self.reload_config
    else
      log.info("Ignoring unknown queue message '#{message}'.")
    end
  end

  def reload_config
    can_use, errors = can_use_config(@config)
    if can_use
      load_config_internal(@config)
    else
      log.error('Wrong configuration.')
      log.info_array('Configuration errors:', errors)
      exit('Aieee!')
    end
  end

  def load_config_internal(config)
    section = config.get_section(section_name)
    apply_settings(section)
    apply_config(config)
  end

end
