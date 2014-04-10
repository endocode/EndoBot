require 'rubygems'
require_relative 'report'
require_relative 'botbase'

class EndoReportBot < BotBase

  def initialize(settings)
    super(settings)
    @file = settings['file']
    @users = settings['users'].split(",")
    @reports = []
  end

  def handle_message(time, nick, text)
    handled = false

    if (create_reports(Date.today, nick, text, @file)) == true
      send_message_to_room("Thanks #{nick} - Your report is saved")
      bot_reports_only_missing
      handled = true
    elsif text.strip =~ /^(.+?): reports$/
      if $1.downcase == bot_nick.downcase
        bot_reports
        handled = true
      end
    end

    unless handled
      super(time, nick, text)
    end
  end

  def setup_scheduler(scheduler)
    scheduler.cron '0 12 * * 1-5' do
      send_messages_to_all
    end
    scheduler.cron '0 22 * * *' do
      clear_reports
    end
  end

  def bot_reports
    if get_users_reports(Date.today).empty?
      send_message_to_room("no Reports yet :(")
    else
      saved_reports = "Reports saved: #{get_users_reports(Date.today)}"
      counter = 0
      for current in @users
        nick = self.get_nick_for_user(current)
        if user_has_report?(nick) == false
          missing_reports = "#{missing_reports}#{nick} "
          counter = counter + 1
        end
      end
      if counter > 0
        send_message_to_room("#{saved_reports}\nReports missing: #{missing_reports}")
      else
        send_message_to_room("Everybody entered a report - thanks!")
      end
    end
  end

  def bot_reports_only_missing
    if get_users_reports(Date.today).empty?
      send_message_to_room("no Reports yet :(")
    else
      counter = 0
      for current in @users
        nick = self.get_nick_for_user(current)
        if user_has_report?(nick) == false
          missing_reports = "#{missing_reports}#{nick} "
          counter = counter + 1
        end
      end
      if counter > 0
        send_message_to_room("Reports missing: #{missing_reports}")
      else
        send_message_to_room("Everybody entered a report - thanks!")
      end
    end
  end

  def send_messages_to_all
    for current in @users
      nick = self.get_nick_for_user(current)
      if user_has_report?(nick) == false
        send_message_to_user("Please submit your daily report.", current)
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
    'endoreportbot'
  end

  def self.get_needed_keys
    self.superclass.get_needed_keys + ['file', 'users']
  end

end
