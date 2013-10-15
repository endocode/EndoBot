require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require_relative 'Report'

class EndoBot

  def initialize
    @reports = []
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

  def get_reports_length()
    return @reports.length
  end
end