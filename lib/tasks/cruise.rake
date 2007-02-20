desc 'Continuous build target'
task :cruise do
  out = ENV['CC_BUILD_ARTIFACTS'] || 'out'
  mkdir_p out unless File.directory? out

  ENV['SHOW_ONLY'] = 'models,lib'
  Rake::Task["test:units:rcov"].invoke
  mv 'coverage/units', "#{out}/unit test coverage"
  
  ENV['SHOW_ONLY'] = 'controllers,helpers'
  Rake::Task["test:functionals:rcov"].invoke
  mv 'coverage/functionals', "#{out}/functional test coverage"
  
  Rake::Task["test:integration"].invoke
end