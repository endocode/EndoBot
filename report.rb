class Report
  attr_accessor :date, :name
  attr_reader :client, :endocode, :help, :done, :saved
  
  def initialize(date, name)
    @date = date
    @name = name
    @done = false
    @saved = false
  end
  
  def set_message(message)
    # Remove any trailing whitespace from user's message
    message.strip!

    if message.start_with? "1." or message.start_with? "Client:"
      message.slice! "1. "
      @client = message
    end
    if message.start_with? "2." or message.start_with? "Endocode:"
      message.slice! "2. "
      @endocode = message
    end
    if message.start_with? "3." or message.start_with? "Help:"
      message.slice! "3. "
      @help = message
    end
  end
  
  def correct_user(name)
    if @name == name
      return true
    end
  end
  
  def set_message_for_user(message, name)
    if correct_user(name)
      self.set_message(message)
    end
  end
  
  def set_done()
    if self.client.to_s.empty? or self.endocode.to_s.empty? or self.help.to_s.empty?
      @done = false
    else
      @done = true
    end
  end
  
  def write_to_file(file)
    File.open(file, 'a+') do |f|  
      f.puts "Report for #{self.date} from #{self.name}"
      f.puts "For client: #{self.client}"
      f.puts "For Endocode: #{self.endocode}"
      f.puts "Impedements/Help needed: #{self.help}"
      f.puts ""
    end  
    @saved = true
  end

  def print_report
    puts "Report for #{self.date} from #{self.name}"
    puts "For client: #{self.client}"
    puts "For Endocode: #{self.endocode}"
    puts "Impediments/Help needed: #{self.help}"
  end
  
end
