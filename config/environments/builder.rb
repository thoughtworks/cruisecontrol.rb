config.cache_classes = true
config.log_path = OPTIONS[:log_file_name] || 'log/builder_WITHOUT_A_NAME.log'
config.log_level = OPTIONS[:verbose] ? :debug : :info
