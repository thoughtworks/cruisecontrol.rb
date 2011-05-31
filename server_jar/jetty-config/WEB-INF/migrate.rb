require File.expand_path("../rails/config/environment", __FILE__)
ActiveRecord::Migration.verbose = true
ActiveRecord::Migrator.migrate(File.expand_path("../rails/db/migrate", __FILE__))
ActiveRecord::Base.clear_all_connections!
