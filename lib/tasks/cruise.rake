desc 'Continuous build target'
task :cruise => ['geminstaller'] do
  # Add local user gem path, in case rcov was installed with non-root access
  ENV['PATH'] = "#{ENV['PATH']}:#{File.join(Gem.user_dir, 'bin')}"

  puts
  puts "[CruiseControl] Build environment:"
  puts "[CruiseControl]   #{`cat /etc/issue`}"
  puts "[CruiseControl]   #{`uname -a`}"
  puts "[CruiseControl]   #{`ruby -v`}"
  `gem env`.each_line {|line| print "[CruiseControl]   #{line}"}
  puts "[CruiseControl]   Local gems:"
  `gem list`.each_line {|line| print "[CruiseControl]     #{line}"}
  puts
    
  out = ENV['CC_BUILD_ARTIFACTS']
  mkdir_p out unless File.directory? out if out

  ENV['SHOW_ONLY'] = 'models,lib,helpers'
  Rake::Task["test:units:rcov"].invoke
  mv 'coverage/units', "#{out}/unit test coverage" if out
  
  ENV['SHOW_ONLY'] = 'controllers'
  Rake::Task["test:functionals:rcov"].invoke
  mv 'coverage/functionals', "#{out}/functional test coverage" if out
  
  Rake::Task["test:integration"].invoke
end
