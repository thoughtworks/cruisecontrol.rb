class ProjectsMigration
  include CommandLine

  def initialize(data_dir = ::Configuration.data_root)
    @data_dir = data_dir
    if File.exists? data_dir and not File.directory? data_dir
      raise "#{data_dir} is not a directory"
    else
      FileUtils.mkdir_p data_dir
    end
  end

  def migrate_data_if_needed
    migration_scripts.each do |script|
      if script_version(script) > current_data_version
        CruiseControl::Log.info "Executing migration script #{script}. This may take some time..."
        clear_cached_pages
        execute "#{Platform.interpreter} #{File.join(migrate_scripts_directory, script)} #{@data_dir}"
        set_data_version(script_version(script))
        CruiseControl::Log.info "Finished #{script}."
      end
    end
  end

  def migration_scripts
    Dir[migrate_scripts_directory.join('*.rb')].map { |path| File.basename(path) }.sort
  end

  def migrate_scripts_directory
    Rails.root.join('db', 'migrate')
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
    Rails.root.join('projects', 'data.version')
  end

  def set_data_version(version)
    File.open(data_version_file, 'w') { |f| f.write(version) }
  end

  def clear_cached_pages
    cached_assets_in_public = [ 'documentation', 'index.html']
    cached_assets_in_public.each do |asset|
      FileUtils.rm_rf Rails.root.join('public', asset)
    end
  end

end
