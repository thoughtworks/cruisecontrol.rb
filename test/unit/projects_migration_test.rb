require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectsMigrationTest < Test::Unit::TestCase                                     
  include FileSandbox

  def setup
    setup_sandbox
    @migration = ProjectsMigration.new(@sandbox.root)
  end

  def teardown
    teardown_sandbox
  end

  def test_migrate_data_if_needed
    @sandbox.new :file => 'data.version', :with_content => '2'
    @migration.expects(:migration_scripts).returns(['001_foo.rb', '002_bar.rb', '003_baz.rb'])
    @migration.expects(:execute).with("ruby #{expected_script_path('003_baz.rb')} #{@sandbox.root}")

    @migration.migrate_data_if_needed
  end

  def test_migrate_data_if_needed_doesnt_do_anything_when_not_needed
    @sandbox.new :file => 'data.version', :with_content => '3'

    @migration.expects(:migration_scripts).returns(['001_foo.rb', '002_bar.rb', '003_baz.rb'])
    @migration.expects(:execute).never

    @migration.migrate_data_if_needed
  end

  def test_migrate_data_does_everything_when_there_is_no_data_version_file
    migration_scripts = ['001_foo.rb', '002_bar.rb', '003_baz.rb']
    expect_scripts_to_be_called_in_order(migration_scripts)
    @migration.expects(:migration_scripts).returns(migration_scripts)
    @migration.migrate_data_if_needed
    assert_equal 3, @migration.current_data_version
  end

  def test_migrate_data_if_needed_should_stop_when_a_script_fails
    @sandbox.new :file => 'data.version', :with_content => '1'

    @migration.expects(:migration_scripts).returns(['001_foo.rb', '002_bar.rb', '003_baz.rb'])

    script_error = StandardError.new
    @migration.expects(:execute).with("ruby #{expected_script_path('002_bar.rb')} #{@sandbox.root}")
    @migration.expects(:execute).with("ruby #{expected_script_path('003_baz.rb')} #{@sandbox.root}").raises(script_error)

    assert_raises(script_error) { @migration.migrate_data_if_needed }

    # migration #3 was broken, current version shall remain at 2
    assert_equal 2, @migration.current_data_version
  end

  def test_should_create_projects_directory_if_it_doesnt_exist_and_run_all_migration_scripts
    projects_dir = "#{@sandbox.root}/projects"
    @migration = ProjectsMigration.new(projects_dir)
    assert_false File.exists?("#{projects_dir}/data.version")

    @migration.expects(:migration_scripts).returns(['001_foo.rb', '002_bar.rb', '003_baz.rb'])
    @migration.expects(:execute).with("ruby #{expected_script_path('001_foo.rb')} #{projects_dir}")
    @migration.expects(:execute).with("ruby #{expected_script_path('002_bar.rb')} #{projects_dir}")
    @migration.expects(:execute).with("ruby #{expected_script_path('003_baz.rb')} #{projects_dir}")

    @migration.migrate_data_if_needed

    assert File.exists?("#{projects_dir}/data.version")
    assert_equal '3', File.read("#{projects_dir}/data.version")
  end

  def test_migration_scripts
    Dir.expects(:[]).with(expected_script_path('*.rb')).returns(['db/001_foo.rb', 'db/003_baz.rb', 'db/002_bar.rb'])

    assert_equal ['001_foo.rb', '002_bar.rb', '003_baz.rb'],
                 @migration.migration_scripts
  end

  def expect_scripts_to_be_called_in_order(migration_scripts)
    migration_scripts = migration_scripts.dup

    @migration.expects(:execute).with() do |*command|
      next_script = migration_scripts.shift
      expected_command = "ruby #{expected_script_path(next_script)} #{@sandbox.root}"
      assert_equal expected_command, command.first
      true
    end.times(migration_scripts.length)
  end

  def expected_script_path(script_name)
    File.join(RAILS_ROOT, 'db', 'migrate', script_name)
  end

end
