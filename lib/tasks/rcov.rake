require 'rcov/rcovtask'

namespace :test do
  targets = ['unit', 'functional', 'integration']
  
  namespace :rcov do
  
    desc "Delete aggregate rcov data."
    task :clean do
      rm_rf   "reports/rcov"
      mkdir_p "reports/rcov"
    end
  
    desc "Open code rcov reports in a browser."
    task :show => 'test:rcov' do
      targets.each do |t|
        system("open reports/rcov/#{t}/index.html")
      end
    end
    
    targets.each do |target|
      desc "Run the #{target} tests using rcov"
      Rcov::RcovTask.new(target) do |t|
        t.libs        << "test"
        t.test_files  = FileList["test/#{target}/*_test.rb"]
        t.verbose     = true
        t.output_dir  = "reports/rcov/#{target}"
        t.rcov_opts   << '--rails'
        t.rcov_opts   << '--exclude gems,__sandbox'
        t.rcov_opts   << '--html'
      end
    end
  end
  task :rcov => (['rcov:clean'] + targets.collect{|t| "rcov:#{t}"})
end

desc "run all tests using rcov"
task :rcov => 'test:rcov'