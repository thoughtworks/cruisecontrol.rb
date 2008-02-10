config.cache_classes = true
config.log_path = CRUISE_OPTIONS[:log_file_name] || 'log/builder_WITHOUT_A_NAME.log'
config.log_level = CRUISE_OPTIONS[:verbose] ? :debug : :info

config.after_initialize do
  require CRUISE_DATA_ROOT + '/site_config' if File.exists?(CRUISE_DATA_ROOT + "/site_config.rb")
end
