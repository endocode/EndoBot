require 'rubygems'
require_relative'report'

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

  def get_todays_reports(date)
    counter = 0
    for current in @reports
      if current.date == date and current.done == true
        counter = counter + 1
      end
    end
    return counter
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
end
