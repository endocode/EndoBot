require 'rubygems'
require 'rufus-scheduler'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

class BotBase

  include Jabber

  def initialize(settings)
    @jid = Jabber::JID.new(settings['jid'])
    @password = settings['password']
    @channel = settings['channel']
  end

  def set_user_mappings(user_mappings)
    @user_mappings = user_mappings
  end

  def get_nick_for_user(user)
    nick = user
    if @user_mappings.has_key?(user)
      nick = @user_mappings[user]
    end
    nick
  end

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
      puts "#{Date.today}, #{nick}, #{text}"
      handle_message(time, nick, text)
    end

    @room.join(@channel)

    @scheduler = Rufus::Scheduler.new
    setup_scheduler(@scheduler)
    @scheduler.join

    @client.close
  end

  def bot_nick
    @room.jid.resource
  end

  def send_message_to_room(message)
    @room.say(message)
  end

  def send_message_to_user(message, user)
    jabber_message = Message.new("#{user}@#{@jid.domain}", message)
    jabber_message.set_type(:chat).set_id('1')
    @client.send(jabber_message)
  end

  def handle_message(time, nick, text)
    # To be overridden by subclass.
    handled = false
    bot_query = bot_nick + ': '
    stripped_msg = text.strip

    if stripped_msg.start_with?(bot_query)
      message = stripped_msg.gsub(/^#{Regexp.escape(bot_query)}/, '')
      handled = handle_direct_message(time, nick, message)
    end

    handled
  end

  def handle_direct_message(time, nick, message)
    # To be overridden by subclass.
    handled = false
    if message == 'exit please'
      puts "exiting"
      @room.exit "Exiting on behalf of #{nick}"
      @scheduler.shutdown
      puts "scheduler shutted down"
      handled = true
    end
    handled
  end

  def setup_scheduler(scheduler)
    # To be overridden by subclass.
  end

  def self.get_needed_keys
    ['jid', 'password', 'channel']
  end

end
