namespace :cruise do
  
  task :info do
    # Add local user gem path, in case rcov was installed with non-root access
    ENV['PATH'] = "#{ENV['PATH']}:#{File.join(Gem.user_dir, 'bin')}"

    puts
    puts "[CruiseControl] === Build environment ==="  if File.exist?('/etc/issue')
    puts "[CruiseControl]   #{`cat /etc/issue`}"      if File.exist?('/etc/issue')

    puts "[CruiseControl] === System information ==="
    puts "[CruiseControl]   #{`uname -a`}"

    puts "[CruiseControl] === Ruby information ==="
    puts "[CruiseControl]   #{`ruby -v`}"

    puts "[CruiseControl] === Gem information ==="
    `ruby -S gem env`.each_line  {|line| print "[CruiseControl]    #{line}"}

    puts "[CruiseControl] === Local gems ==="
    `ruby -S gem list`.each_line {|line| print "[CruiseControl]    #{line}"}
    puts
  end
  
  desc "Continuous build target"
  task :all => [:info, 'rcov'] do
    out = ENV['CC_BUILD_ARTIFACTS']
    mkdir_p out unless File.directory? out if out
    mv 'reports/rcov', "#{out}" if out
  end
end


desc 'Continuous build target'
task :cruise => ['cruise:all']