class ProjectsMigration
  include CommandLine
  include FileUtils

  def initialize(data_dir = CRUISE_DATA_ROOT)
    @data_dir = data_dir
    if File.exists? data_dir and not File.directory? data_dir
      raise "#{data_dir} is not a directory"
    else
      mkdir_p data_dir
    end
  end

  def migrate_data_if_needed
    migration_scripts.each do |script|
      if script_version(script) > current_data_version
        CruiseControl::Log.info "Executing migration script #{script}. This may take some time..."
        clear_cached_pages
        execute "ruby #{File.join(migrate_scripts_directory, script)} #{@data_dir}"
        set_data_version(script_version(script))
        CruiseControl::Log.info "Finished #{script}."
      end
    end
  end

  def migration_scripts
    Dir[File.join(migrate_scripts_directory, '*.rb')].map { |path| File.basename(path) }.sort
  end

  def migrate_scripts_directory
    File.join(RAILS_ROOT, 'db', 'migrate')
  end

  def script_version(script_name)
    raise "Migration script name #{script_name} doesn't start with three digits and underscore" unless script_name =~ /^\d\d\d_/
    script_name.to_i
  end

  def current_data_version
    if File.exists?(data_version_file)
      File.read(data_version_file).to_i 
    elsif File.exists?(old_data_version_file)
      File.read(old_data_version_file).to_i
    else
      0
    end
  end

  def data_version_file
    File.join(@data_dir, 'data.version')
  end
  
  def old_data_version_file
    File.join(RAILS_ROOT, 'projects', 'data.version')
  end

  def set_data_version(version)
    File.open(data_version_file, 'w') { |f| f.write(version) }
  end

  def clear_cached_pages
    cached_assets_in_public = [ 'documentation', 'index.html']
    cached_assets_in_public.each do |asset|
      rm_rf File.join(RAILS_ROOT, 'public', asset)
    end
  end

end
