class Report
  attr_accessor :date, :name
  attr_reader :yesterday, :today, :impediments, :help, :sparetime, :done, :saved
  def initialize(date, name)
    @date = date
    @name = name
    @done = false
    @saved = false
  end
  
  def set_message(message)
    #puts self.yesterday
    if message.start_with? "1." or message.start_with? "Yesterday:"
      message.slice! "1. "
      @yesterday = message
    end
    if message.start_with? "2." or message.start_with? "Today:"
      message.slice! "2. "
      @today = message
    end
    if message.start_with? "3." or message.start_with? "Impediments:"
      message.slice! "3. "
      @impediments = message
    end
    if message.start_with? "4." or message.start_with? "Help:"
      message.slice! "4. "
      @help = message
    end
    if message.start_with? "5." or message.start_with? "Sparetime:"
      message.slice! "5. "
      @sparetime = message
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
    if self.yesterday.to_s.empty? or self.today.to_s.empty? or self.impediments.to_s.empty? or self.help.to_s.empty? or self.sparetime.to_s.empty?
      @done = false
    else
      @done = true
    end
  end
  
  def write_to_file(file)
    File.open(file, 'a+') do |f|  
      f.puts "Report for #{self.date} from #{self.name}"
      f.puts "Yesterday: #{self.yesterday}"
      f.puts "Today: #{self.today}"
      f.puts "Impediments: #{self.impediments}"
      f.puts "Help needed: #{self.help}"
      f.puts "Sparetime: #{self.sparetime}"
    end  
    @saved = true
  end

  def print_report
    puts "Report for #{self.date} from #{self.name}"
    puts "Yesterday: #{self.yesterday}"
    puts "Today: #{self.today}"
    puts "Impediments: #{self.impediments}"
    puts "Help needed: #{self.help}"
    puts "Sparetime: #{self.sparetime}"
  end
  
end