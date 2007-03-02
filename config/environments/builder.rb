config.cache_classes = true
config.log_path = CRUISE_OPTIONS[:log_file_name] || 'log/builder_WITHOUT_A_NAME.log'
config.log_level = CRUISE_OPTIONS[:verbose] ? :debug : :info