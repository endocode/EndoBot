require 'inifile'

# Stores configuration file.
class BotConfig

  def initialize(ini_filename)
    @ini_filename = ini_filename
    reload
  end

  def reload
    @ini_file = IniFile.load(@ini_filename)
    if @ini_file == nil
      raise "#{@ini_filename} not found."
    end
  end

  def get_common_section
    get_section('common')
  end

  def has_section?(name)
    @ini_file.has_section?(name)
  end

  def get_section(name)
    section = {}
    if has_section?(name)
      section = @ini_file[name]
    end
    section
  end

  def get_socket_path
    File.expand_path(self.get_common_section.fetch('socket_path', '/tmp/endobot.sock'))
  end

  def get_pid_directory
    File.expand_path(self.get_common_section.fetch('pid_dir', '/tmp'))
  end

  def get_log_path
    File.expand_path(self.get_common_section.fetch('log_path', '/var/log/endobot.log'))
  end

  def get_log_level
    self.get_common_section.fetch('log_level', 'INFO').to_sym
  end

  def get_user_mappings
    user_mappings = {}
    if @ini_file.has_section?('user-mappings')
      user_mappings = @ini_file['user-mappings']
    end
    user_mappings
  end

end
