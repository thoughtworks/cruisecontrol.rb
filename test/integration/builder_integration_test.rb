require File.dirname(__FILE__) + '/../test_helper'

class BuilderIntegrationTest < Test::Unit::TestCase
  include FileSandbox

  def test_checkout
    # with_project calls svn.checkout
    with_project 'passing_project' do |project, sandbox|
      assert File.exists?("passing_project/work/passing_test.rb")
    end
  end

  def test_new_revisions
    with_project('passing_project', :revision => 2) do |project, sandbox|
      expected_revisions = [
          Revision.new(3, 'averkhov', DateTime.parse('2007-01-11T21:01:43.441137Z'),
                       'another revision',
                       [ChangesetEntry.new('M', '/passing_project/revision_label.txt')]),
          Revision.new(4, 'averkhov', DateTime.parse('2007-01-11T21:02:03.471105Z'),
                       'and one more revision, for good measure',
                       [ChangesetEntry.new('M', '/passing_project/revision_label.txt')]),
          Revision.new(7, 'averkhov', DateTime.parse('2007-01-13T01:05:26.919332Z'),
                       'Making both revision labels up to date',
                       [ChangesetEntry.new('M', '/passing_project/revision_label.txt'),
                        ChangesetEntry.new('M', '/failing_project/revision_label.txt')])
          ]
      actual = Subversion.new.revisions_since(project, 2)
      
      assert_equal expected_revisions, actual
    end
  end

  def test_new_revisions_should_return_an_empty_array_for_uptodate_local_copy
    with_project 'passing_project' do |project, sandbox|
      assert_equal [],  Subversion.new.revisions_since(project, 7)
    end
  end

  def test_build_if_necessary
    with_project('passing_project', :revision => 2) do |project, sandbox|
      sandbox.new :file=> 'passing_project/cruise_config.rb'
      sandbox.new :file=> 'passing_project/build-2/build_status.success'
      
      project.config_tracker.update_timestamps

      assert_equal '2', File.read("#{sandbox.root}/passing_project/work/revision_label.txt").chomp
       result = project.build_if_necessary

      assert result.is_a?(Build)

      assert_equal true, result.successful?
      
      build_dir = Dir["#{sandbox.root}/passing_project/build-7-success.*"][0]
      assert build_dir
      assert File.exists?("#{build_dir}/changeset.log")
      assert File.exists?("#{build_dir}/build.log")
    end
  end

  def test_build_if_necessary_should_abort_build_when_local_config_modified
    with_project('passing_project', :revision => 2) do |project, sandbox|
      sandbox.new :file=> 'passing_project/cruise_config.rb'

      assert_throws(:reload_project) { project.build_if_necessary }
      assert_false File.exists?("#{sandbox.root}/passing_project/build-7/")
    end
  end

  def test_build_if_necessary_should_abort_build_when_central_config_modified
    with_project('project_with_central_config', :revision => 16) do |project, sandbox|
      assert_throws(:reload_project) { project.build_if_necessary }
      assert Dir["#{sandbox.root}/project_with_central_config/build*"].empty?
      assert_equal "$config_loaded = true\n\n",
                   File.read("#{sandbox.root}/project_with_central_config/work/cruise_config.rb")
    end
  end

  def test_build_if_necessary_should_update_and_reload_broken_central_config
    with_project('project_with_central_config', :revision => 18) do |project, sandbox|
      assert_equal "raise 'Error in config file'\n\n", 
                   File.read("#{sandbox.root}/project_with_central_config/work/cruise_config.rb")
      begin
        $config_loaded = false
        project.load_config
        assert $config_loaded
      ensure
        $config_loaded = nil
      end
    end
  end

  def test_build_if_necessary_for_a_failing_build
    with_project('failing_project', :revision => 6) do |project, sandbox|
      result = project.build_if_necessary

      assert result.is_a?(Build)
      assert_equal true, result.failed?

      build_dir = Dir["failing_project/build-7-failed.*"][0]
      assert build_dir
      assert_equal false, file("#{build_dir}/build_status.success").exists?

      assert file("#{build_dir}/changeset.log").exists?
      assert file("#{build_dir}/build.log").exists?
    end
  end

  def test_build_if_necessary_should_return_nil_when_no_changes_were_made
    with_project 'passing_project' do |project, sandbox|
      sandbox.new :file=> 'passing_project/cruise_config.rb'
      sandbox.new :file=>'passing_project/build-7/build_status.success'     
      result = project.build_if_necessary      
      assert_nil result
      # test existence and contents of log files
    end
  end
      
  def test_build_should_still_build_even_when_no_changes_were_made
    with_project('passing_project', :revision => 7) do |project, sandbox|
      status_file_path = 'passing_project/build-7/build_status.success'
      sandbox.new :file=> status_file_path  
      
      new_status_file_path = 'passing_project/build-7.1/build_status.success.*'    
      new_status_file_full_path = "#{sandbox.root}/#{new_status_file_path}"
    
      result = project.build
      assert result.is_a?(Build)

      assert_equal true, result.successful?

      assert Dir["passing_project/build-7.1-success.*"][0]
     end
  end  
    
  def test_builder_should_set_RAILS_ENV_to_test_and_invoke_db_migrate_and_test_instead_of_if_these_tasks_are_defined
    with_project('project_with_db_migrate') do |project, sandbox|
      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")

      expected_output = "RAILS_ENV=test\ndb:migrate invoked\n[CruiseControl] Invoking Rake task \"default\"\ndefault invoked\n"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
    
  end

  def test_builder_should_be_transparent_to_RAILS_ENV
    with_project('project_with_cruise_and_default_tasks') do |project, sandbox|
      project.build_command = 'rake cruise RAILS_ENV=foo'
      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")

      expected_output = "RAILS_ENV=\"foo\"\ncruise invoked\n"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
  end

  def test_custom_build_command
    with_project('project_with_cruise_and_default_tasks') do |project, sandbox|
      project.build_command = 'echo Vasya_was_here'

      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")
      
      expected_output = "Vasya_was_here"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
    
  end

  def test_custom_rake_task
    with_project('project_with_custom_rake_task') do |project, sandbox|
      project.rake_task = 'my_build'

      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")
      
      expected_output = "my_build invoked\n"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
    
  end

  def test_multiple_custom_rake_tasks
    with_project('project_with_custom_rake_task') do |project, sandbox|
      project.rake_task = 'my_build my_deploy'

      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")
      
      expected_output = "my_build invoked\n[CruiseControl] Invoking Rake task \"my_deploy\"\nmy_deploy invoked\n"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
    
  end

  def test_should_reconnect_to_database_after_db_test_purge_in_cc_build
    with_project 'project_with_db_test_purge_and_migrate' do |project, sandbox|
      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")
      expected_output = "db-test-purge\nESTABLISH_CONNECTION\n[CruiseControl] Invoking Rake task \"db:migrate\"\ndb-migrate\n"
      assert build_log.include?(expected_output), "#{expected_output.inspect} not found in build log:\n#{build_log}"
    end
    
  end
  
  def test_should_break_build_if_no_migration_scripts_but_database_yml_exists
    with_project 'project_with_no_migration_scripts_but_database_yml_exists' do |project, sandbox|
      build = project.build
      build_log = File.read("#{build.artifacts_directory}/build.log")
      assert !build_log.include?("db-test-purge") 
      assert !build_log.include?("db-migrate")       
      error_message = "No migration scripts found in db/migrate/ but database.yml exists, " + 
                      "CruiseControl won't be able to build the latest test database. Build aborted."
      assert build_log.include?(error_message), 
          "#{error_message.inspect} not found in build log:\n#{build_log}"
    end
  end
  
  def fixture_repository_url
    repository_path = File.expand_path("#{RAILS_ROOT}/test/fixtures/svn-repo")
    urlified_path = repository_path.sub(/^[a-zA-Z]:/, '').gsub('\\', '/')
    "file://#{urlified_path}"
  end

  def with_project(project_name, options = {}, &block)
    in_sandbox do |sandbox|
      svn = Subversion.new :url => "#{fixture_repository_url}/#{project_name}"
      svn.checkout "#{sandbox.root}/#{project_name}/work", options[:revision]
      
      project = Project.new(project_name)
      project.path = "#{sandbox.root}/#{project_name}"

      block.call(project, sandbox)
    end
  end

end
