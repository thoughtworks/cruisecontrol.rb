class ProjectsMigration
  include CommandLine

  def initialize(projects_directory = Configuration.projects_directory)
    @projects_directory = projects_directory
  end

  def migrate_data_if_needed()
    migration_scripts.each do |script|
      script_version = script.to_i
      if script_version > current_data_version
        execute "ruby #{File.join(migrate_scripts_directory, script)} #{@projects_directory}"
        File.open(data_version_file, 'w') { |f| f.write(script_version) }
      end
    end
  end

  def migration_scripts
    Dir[File.join(migrate_scripts_directory, '*.rb')].map { |path| File.basename(path) }.sort
  end

  def migrate_scripts_directory
    File.join(RAILS_ROOT, 'db', 'migrate')
  end

  def current_data_version
    File.exists?(data_version_file) ? File.read(data_version_file).to_i : 0
  end

  def data_version_file
    File.join(@projects_directory, 'data.version')
  end

end
