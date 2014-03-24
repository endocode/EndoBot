require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'rufus-scheduler'
require_relative 'report'

class EndoBot
  
  include Jabber

  def initialize(settings)
    @jid = settings['jid']
    @password = settings['password']
    @channel = settings['channel']
    @file = settings['file']
    @users = settings['users'].split(",")
    @reports = []
  end
  
  def connect_bot
    # Jabber::debug = true
    @client = Jabber::Client.new(Jabber::JID.new(@jid))
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
      if (create_reports(Date.today, nick, text, @file)) == true
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

    @room.join(@channel)
    
    setup_scheduler

    Thread.stop
    @client.close  
  end

  def setup_scheduler
    scheduler = Rufus::Scheduler.new
    scheduler.cron '0 12 * * 1-5' do
      send_messages_to_all
    end
    scheduler.cron '0 22 * * *' do
      clear_reports
    end
    scheduler.join
  end

  def bot_reports
    if get_users_reports(Date.today).empty?
      @room.say("no Reports yet :(")
    else
      saved_reports = "Reports saved: #{get_users_reports(Date.today)}"
      counter = 0
      for current in @users
        if user_has_report?(current) == false
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
    if get_users_reports(Date.today).empty?
      @room.say("no Reports yet :(")
    else
      counter = 0
      for current in @users
        if user_has_report?(current) == false
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
      if user_has_report?(current) == false
        @client.send Message::new("#{current}@#{Jabber::JID.new(ARGV[0]).domain}","Please submit your daily report.").set_type(:chat).set_id('1')
      end
    end
  end

  def create_reports(date, name, message, file)
    for current in @reports
      if current.name == name and current.date == date
        current.set_message_for_user(message, name)
        @contains = true
      else
        @contains = false
      end
    end

    if @contains == false or @reports.length == 0
      report = Report.new(date, name)
      report.set_message(message)
      @reports << report
    end

    for current in @reports
      current.set_done()
      if current.done == true and current.saved == false
        current.write_to_file(file)
        return true
      end
    end
  end

  def get_reports_length
    return @reports.length
  end

  def get_todays_reports(date)
    counter = 0
    for current in @reports
      if current.date == date and current.done == true
        counter = counter + 1
      end
    end
    return counter
  end

  def user_has_report?(name)
    for current in @reports
      if current.name == name and current.date == Date.today
        return true
      end
    end
    return false
  end

  def get_users_reports(date)
    result = ""
    for current in @reports
      if current.date == date and current.done == true
        result = "#{result}#{current.name} "
      end
    end
    return result
  end

  def clear_reports
    @reports = []
  end

  def self.ini_section
    'endobot'
  end

  def self.get_needed_keys
    ['jid', 'password', 'channel', 'file', 'users']
  end

end
