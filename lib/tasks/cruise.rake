desc 'Continuous build target'
task :cruise  => ['geminstaller'] do
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

desc 'Install development dependencies via GemInstaller'
task :geminstaller do
  begin
    require 'geminstaller'
  rescue LoadError
    `gem install geminstaller`
    puts "GemInstaller installed, please try build again"
  end
  
  GemInstaller.install("--config=#{RAILS_ROOT}/test/geminstaller.yml")
end