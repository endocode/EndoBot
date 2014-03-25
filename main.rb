require_relative 'endoreportbot'
require_relative 'botconfig'

ini = 'endobotconfig.ini'

if ARGV.size > 0
  ini = ARGV[0]
end

status = 0

begin
  bot_threads = []
  config = BotConfig.new(ini)

  [EndoReportBot].each do |bot_class|
    settings = config.get_valid_section(bot_class)
    if settings != nil
      puts "Running #{bot_class.to_s} instance."
      bot_instance = bot_class.new(settings)
      bot_threads << Thread.new { bot_instance.run }
    else
      puts "Not running #{bot_class.to_s} instance - no valid configuration."
    end
  end

  if bot_threads.empty?
    puts 'No bots are running, quitting.'
    status = 1
  else
    puts 'Waiting for bots to quit'
    bot_threads.each { |thread| thread.join }
  end
rescue StandardError => ex
  puts "Error: #{ex}"
  status = 1
end

exit status
