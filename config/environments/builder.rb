config.cache_classes = true
config.log_path = "log/#{OPTIONS[:project_name]}_builder.log"
config.log_level = OPTIONS[:verbose] ? :debug : :info
