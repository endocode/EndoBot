require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'rufus-scheduler'
require_relative 'endobot'

if ARGV.size != 5
  puts "Usage: #{$0} <jid> <password> <room@conference/nick> <outputfile> <user1,user2,...>"
  exit
end

include Jabber

@jid = ARGV[0]
@password = ARGV[1]
@channel = ARGV[2]
@file = ARGV[3]
@users = ARGV[4].split(",")
@bot = EndoBot.new()
@reports = []
@room
@scheduler = Rufus::Scheduler.new

#Jabber::debug = true
@client = Jabber::Client.new(Jabber::JID.new(ARGV[0]))
@client.allow_tls = false
@client.connect
@client.auth(@password)
@client.send(Presence.new.set_type(:available))

mainthread = Thread.current

@room = Jabber::MUC::SimpleMUCClient.new(@client)

# SimpleMUCClient callback-blocks

@room.on_join { |time,nick|
  puts "#{nick} has joined!"
  puts "Users: " + @room.roster.keys.join(', ')
  # @users << nick
}

@room.on_leave { |time,nick|
  puts "#{nick} has left!"
  # @users.delete(nick)
}

@room.on_message { |time,nick,text|
  puts "#{Date.today}, #{nick}, #{text}"
  if (@bot.create_reports(Date.today, nick, text, @file)) == true
    @room.say("Thanks #{nick} - Your report is saved")
    bot_reports_only_missing
  end

  # Bot: exit please
  if text.strip =~ /^(.+?): exit please$/
    if $1.downcase == @room.jid.resource.downcase
      puts "exiting"
      @room.exit "Exiting on behalf of #{nick}"
      mainthread.wakeup
    end
  end

  # Bot: reports
  if text.strip =~ /^(.+?): reports$/
    if $1.downcase == @room.jid.resource.downcase
      bot_reports
    end
  end
}

@room.on_room_message { |time,text|
  print_line time, "- #{text}"
}

@room.join(ARGV[2])

def bot_reports
  if @bot.get_users_reports(Date.today).empty?
    @room.say("no Reports yet :(")
  else
    saved_reports = "Reports saved: #{@bot.get_users_reports(Date.today)}"
    counter = 0
    for current in @users
      if @bot.user_has_report?(current) == false
        missing_reports = "#{missing_reports}#{current} "
        counter = counter + 1
      end
    end
    if counter > 0
      @room.say("#{saved_reports}\nReports missing: #{missing_reports}")
    else
      @room.say("Everybody entered a report - thanks!")
    end
  end
end

def bot_reports_only_missing
  if @bot.get_users_reports(Date.today).empty?
    @room.say("no Reports yet :(")
  else
    counter = 0
    for current in @users
      if @bot.user_has_report?(current) == false
        missing_reports = "#{missing_reports}#{current} "
        counter = counter + 1
      end
    end
    if counter > 0
      @room.say("Reports missing: #{missing_reports}")
    else
      @room.say("Everybody entered a report - thanks!")
    end
  end
end

def send_messages_to_all
  for current in @users
    if @bot.user_has_report?(current) == false
      @client.send Message::new("#{current}@#{Jabber::JID.new(ARGV[0]).domain}","Please submit your daily report.").set_type(:chat).set_id('1')
    end
  end
end

@scheduler.cron '0 12 * * *' do
  send_messages_to_all
end

@scheduler.join

Thread.stop
@client.close