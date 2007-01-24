class Subversion

  include CommandLine

  attr_accessor :url, :username, :password

  def initialize(options = {})
    @url, @username, @password = options.delete(:url), options.delete(:username), options.delete(:password)
    raise "don't know how to handle '#{options.keys.first}'" if options.length > 0
  end

  def self.checkout(target_directory, options)
    revision = options.delete(:revision)
    Subversion.new(options).checkout(target_directory, revision)
  end
    
  # FIXME: options should be passed either to the constructor, or to the method, not both
  def checkout(target_directory, revision = nil)
    @url or raise 'URL not specified'

    cmd = "svn --non-interactive co #{@url} #{target_directory}"
    cmd << " --username #{@username}" if username
    cmd << " --password #{@password}" if password
    cmd << " --revision #{revision_number(revision)}" if revision

    # need to read from command output, because otherwise tests break
    execute(cmd) { |io| io.readlines }
  end

  def info(project)
    result = Hash.new
    Dir.chdir(project.local_checkout) do
      execute 'svn --non-interactive info' do |io|
        io.each_line do |line|
          line.chomp!
          next if line.empty?
          match = line.match(/^([^:]+):\s*(.*)$/)
          raise "#{line.inspect} does not match 'name: value' pattern" unless match
          key, value = match[1..2]
          result[key] = value
        end
      end
    end
    result
  end

  def latest_revision(project)
    last_locally_known_revision = info(project)['Last Changed Rev']
    svn_output = execute_in_local_copy(project, 
        "svn --non-interactive log --revision HEAD:#{last_locally_known_revision} --verbose")
    SubversionLogParser.new.parse_log(svn_output).first
  end

  def current_revision(project)
    info(project)["Revision"].to_i
  end

  def revisions_since(project, revision_number)
    svn_output = execute_in_local_copy(project, "svn --non-interactive log --revision HEAD:#{revision_number} --verbose")
    new_revisions = SubversionLogParser.new.parse_log(svn_output).reverse
    new_revisions.delete_if { |r| r.number == revision_number }
    new_revisions
  end

  def update(project, revision)
    svn_output = execute_in_local_copy(project, "svn --non-interactive update --revision #{revision_number(revision)}")
    SubversionLogParser.new.parse_update(svn_output)
  end

  def revision_number(revision)
    revision.respond_to?(:number) ? revision.number : revision.to_i
  end

  def memento
    options = []
    options << ":url => '#{url}'" if url
    options << ":username => '#{username}'" if username
    options << ":password => '#{password}'" if password
    "Subversion.new(#{options.join(", ")})"
  end

  def execute_in_local_copy(project, command)
    Dir.chdir(project.local_checkout) do
      execute(command) { |io| return io.readlines }
    end
  end

end
