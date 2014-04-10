require 'rubygems'
require 'inifile'

class BotConfig

  def initialize(ini_filename)
    @ini_file = IniFile.load(ini_filename)
    if @ini_file == nil
      raise "#{ini_filename} not found."
    end
  end

  def get_valid_section(bot_class)
    name = bot_class.ini_section
    valid_section = nil
    if @ini_file.has_section?(name)
      section = @ini_file[name]
      valid_section = section
      bot_class.get_needed_keys.each do |key|
        unless section.has_key?(key)
          valid_section = nil
          break
        end
      end
    end
    valid_section
  end

  def get_user_mappings
    user_mappings = {}
    if @ini_file.has_section?('user-mappings')
      user_mappings = @ini_file['user-mappings']
    end
    user_mappings
  end

end
