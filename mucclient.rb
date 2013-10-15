require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require_relative 'EndoBot'

if ARGV.size != 4
  puts "Usage: #{$0} <jid> <password> <room@conference/nick> <outputfile>"
  exit
end


@jid = ARGV[0]
@password = ARGV[1]
@channel = ARGV[2]
@file = ARGV[3]
@bot = EndoBot.new()
@reports = []
@room

#Jabber::debug = true
client = Jabber::Client.new(Jabber::JID.new(ARGV[0]))
client.allow_tls = false
client.connect
client.auth(@password)

mainthread = Thread.current

@room = Jabber::MUC::SimpleMUCClient.new(client)

# SimpleMUCClient callback-blocks

@room.on_join { |time,nick|
  puts "#{nick} has joined!"
  puts "Users: " + @room.roster.keys.join(', ')
  #room.say("Hello #{nick}")
}

@room.on_leave { |time,nick|
  puts "#{nick} has left!"
}

@room.on_message { |time,nick,text|
  time = "#{Time.new.year}-#{Time.new.month}-#{Time.new.day}"
  puts "#{time.to_s}, #{nick}, #{text}"
  if (@bot.create_reports(time.to_s, nick, text, @file)) == true
    @room.say("Thanks #{nick} - Your report is saved")
  end

  # Bot: exit please
  if text.strip =~ /^(.+?): exit please$/
    if $1.downcase == @room.jid.resource.downcase
      puts "exiting"
      @room.exit "Exiting on behalf of #{nick}"
      mainthread.wakeup
    end
  end
}

@room.on_room_message { |time,text|
  print_line time, "- #{text}"
}

@room.join(ARGV[2])

Thread.stop
client.close