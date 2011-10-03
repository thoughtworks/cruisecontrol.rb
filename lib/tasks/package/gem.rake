namespace :package do
  namespace :gem do
    def gem_dir
      package_dir.join("gem")
    end

    desc "Package CruiseControl.rb as a gem."
    task :package do
      sh("gem build cruisecontrolrb.gemspec")
      gem_file = Pathname.glob("*.gem").first
      verbose(true) { gem_file.rename(gem_dir.join(gem_file).to_s) }
    end

    desc "Remove all existing packaged gems."
    task :clean do
      verbose(true) { gem_dir.rmdir rescue nil }
      verbose(true) { gem_dir.mkpath }
    end

    task :test => "package:gem" do
      built_gems = Pathname.glob("#{gem_dir}/*.gem")
      raise "Gem not built successfully" if built_gems.empty?
      gem_file = built_gems.first

      sh "rvm gemset use ccrb-test"
      sh "rvm gemset list"
      sh "rvm gemset empty ccrb-test"

      sh "gem install #{gem_file}"
      sh "cruise start"
      sh "rvm gemset use ccrb"
    end
  end
end