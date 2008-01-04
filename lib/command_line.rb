require 'English'

# borrowed (with modifications) from the RSCM project
module CommandLine

  QUOTE_REPLACEMENT = (Platform.family == "mswin32") ? '"' : '\\"'
  LESS_THAN_REPLACEMENT = (Platform.family == "mswin32") ? '<' : '\\<'

  class OptionError < StandardError; end
  class ExecutionError < StandardError
    attr_reader :cmd, :dir, :exitstatus, :stderr
    def initialize(cmd, full_cmd, dir, exitstatus, stderr)
      @cmd, @full_cmd, @dir, @exitstatus, @stderr = cmd, full_cmd, dir, exitstatus, stderr
    end
    def to_s
      "\ndir : #{@dir}\n" +
      "command : #{@cmd}\n" +
      "executed command : #{@full_cmd}\n" +
      "exitstatus: #{@exitstatus}\n" +
      "STDERR TAIL START\n#{@stderr}\nSTDERR TAIL END\n"
    end
  end

  # Executes +cmd+.
  # If the +:stdout+ and +:stderr+ options are specified, a line consisting
  # of a prompt (including +cmd+) will be appended to the respective output streams will be appended
  # to those files, followed by the output itself. Example:
  #
  #   CommandLine.execute("echo hello world", {:stdout => "stdout.log", :stderr => "stderr.log"})
  #
  # will result in the following being written to stdout.log:
  #
  #   /Users/aslakhellesoy/scm/buildpatterns/repos/damagecontrol/trunk aslakhellesoy$ echo hello world
  #   hello world
  #
  # -and to stderr.log:
  #   /Users/aslakhellesoy/scm/buildpatterns/repos/damagecontrol/trunk aslakhellesoy$ echo hello world
  #
  # If a block is passed, the stdout io will be yielded to it (as with IO.popen). In this case the output
  # will not be written to the stdout file (even if it's specified):
  #
  #   /Users/aslakhellesoy/scm/buildpatterns/repos/damagecontrol/trunk aslakhellesoy$ echo hello world
  #   [output captured and therefore not logged]
  #
  # If the exitstatus of the command is different from the value specified by the +:exitstatus+ option
  # (which defaults to 0) then an ExecutionError is raised, its message containing the last 400 bytes of stderr
  # (provided +:stderr+ was specified)
  #
  # You can also specify the +:dir+ option, which will cause the command to be executed in that directory
  # (default is current directory).
  #
  # You can also specify a hash of environment variables in +:env+, which will add additional environment variables
  # to the default environment.
  #
  # Finally, you can specify several commands within one by separating them with '&&' (as you would in a shell).
  # This will result in several lines to be appended to the log (as if you had executed the commands separately).
  #
  # See the unit test for more examples.
  def execute(cmd, options={}, &proc)
    raise "Can't have newline in cmd" if cmd =~ /\n/
    options = {
        :dir => Dir.pwd,
        :env => {},
        :mode => 'r',
        :exitstatus => 0 }.merge(options)

    options[:stdout] = File.expand_path(options[:stdout]) if options[:stdout]
    options[:stderr] = File.expand_path(options[:stderr]) if options[:stderr]

    Dir.chdir(options[:dir]) do
      return e(cmd, options, &proc)
    end
  end
  module_function :execute

  private

  def e(cmd, options, &proc)
    full_cmd = full_cmd(cmd, options, &proc)

    options[:env].each{|k,v| ENV[k]=v}
    begin
      CruiseControl::Log.debug "#{Platform.prompt} #{format_for_printing(cmd)}" if options[:stdout].nil?
      result = IO.popen(full_cmd, options[:mode]) do |io|
        if proc
          proc.call(io)
        else
          io.each_line do |line|
            STDOUT.puts line if options[:stdout].nil?
          end
        end
      end
      exit_status = $CHILD_STATUS
      raise "$CHILD_STATUS is nil " unless exit_status
      verify_exit_code(exit_status, cmd, full_cmd, options)
      return result
    rescue Errno::ENOENT => e
      if options[:stderr]
        File.open(options[:stderr], "a") {|io| io.write(e.message)}
      else
        STDERR.puts e.message
        STDERR.puts e.backtrace.map { |line| "    #{line}" }
      end
      raise ExecutionError.new(cmd, full_cmd, options[:dir], nil, e.message)
    end
  end
  module_function :e

  def full_cmd(cmd, options, &proc)
    stdout_opt, stderr_opt = redirects(options)

    capture_info_command = (block_given? && options[:stdout]) ?
        "echo [output captured and therefore not logged] >> #{options[:stdout]} && " :
        ''

    cmd = escape_and_concatenate(cmd) unless cmd.is_a? String

    stdout_prompt_command = options[:stdout] ?
                              "echo #{Platform.prompt} #{cmd} >> #{options[:stdout]} && " :
                              ''

    stderr_prompt_command = options[:stderr] && options[:stderr] != options[:stdout] ?
                              "echo #{Platform.prompt} #{cmd} >> #{options[:stderr]} && " :
                              ''

    redirected_command = block_given? ? "#{cmd} #{stderr_opt}" : "#{cmd} #{stdout_opt} #{stderr_opt}"

    stdout_prompt_command + capture_info_command + stderr_prompt_command + redirected_command
  end
  module_function :full_cmd

  def verify_exit_code(exit_status, cmd, full_cmd, options)
    if exit_status.exitstatus != options[:exitstatus]
      if options[:stderr] && File.exist?(options[:stderr])
        File.open(options[:stderr]) do |errio|
          begin
            errio.seek(-1200, IO::SEEK_END)
          rescue Errno::EINVAL
            # ignore - it just means we didn't have 400 bytes.
          end
          error_message = errio.read
        end
      else
        error_message = "#{options[:stderr]} doesn't exist"
      end
      raise ExecutionError.new(cmd, full_cmd, options[:dir] || Dir.pwd, exit_status.exitstatus, error_message)
    end
  end
  module_function :verify_exit_code

  def redirects(options)
    stdout_opt = options[:stdout] ? ">> #{options[:stdout]}" : ""

    # redirecting stderr to stdout if they are the same file avoids a file lock conflict
    stderr_opt =
        case(options[:stderr])
        when nil then ''
        when options[:stdout] then '2>&1'
        else "2>> #{options[:stderr]}"
        end

    # let's hope that nobody has slashes in directory names on their win32 file system
    if Platform.family == 'mswin32'
      stdout_opt.gsub!('/', '\\')
      stderr_opt.gsub!('/', '\\')
    end

    [stdout_opt, stderr_opt]
  end
  module_function :redirects
  
  def escape_and_concatenate(cmd)
    cmd.map { |item| escape(item) }.join(' ')
  end
  module_function :escape_and_concatenate

  def escape(item)
    if Platform.family == 'mswin32'
      escaped_characters = /\\|&|\||>|<|\^/
      escape_symbol = '^'
      quote_argument = (item =~ /\s/) 
    else
      escaped_characters = /"|'|<|>| |&|\||\(|\)|\\|;/
      escape_symbol = '\\'
      quote_argument_with_spaces = false
    end
    escaped_value = item.to_s.gsub(escaped_characters) { |match| "#{escape_symbol}#{match}" }
    if quote_argument
      '"' + escaped_value + '"'
    else
      escaped_value
    end
  end
  module_function :escape

  # command can be a string or an array
  def format_for_printing(command)
    if command.is_a? String
      command
    else
      command.join(' ')
    end
  end
  module_function :format_for_printing
  
end