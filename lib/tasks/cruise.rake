desc 'Continuous build target'
task :cruise => ['test:units:rcov', 'test:functionals:rcov', 'test:integration'] do 
  out = ENV[CC_BUILD_ARTIFACTS] || 'out'
  mv 'coverage/units', "#{out}/unit test coverage"
  mv 'coverage/functionals', "#{out}/functional test coverage"
end