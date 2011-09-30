task :package => ["package:gem"]

namespace :package do
  def package_dir
    Pathname.new("pkg")
  end

  desc "Package CruiseControl.rb as a gem."
  task :gem => [ :clean, :prepare ] do
    system "gem build cruisecontrolrb.gemspec"
    gem_file = Pathname.glob("*.gem").first
    verbose(true) { gem_file.rename(package_dir.join(gem_file)) }
  end

  desc "Remove all existing packaged files."
  task :clean do
    verbose(true) { package_dir.rmdir rescue nil }
  end

  desc "Install all dependencies using Bundler's deployment mode."
  task :prepare do
    verbose(true) { package_dir.mkdir rescue nil }
  end

  namespace :gem do
    task :test => "package:gem" do
      built_gems = Pathname.glob("#{package_dir}/*.gem")
      raise "Gem not built successfully" if built_gems.empty?
      gem_file = built_gems.first

      system "rvm gemset create ccrb-test"
      system "rvm gemset use ccrb-test"
      system "rvm --force gemset empty ccrb-test"

      system "gem install #{gem_file}"
      system "cruise start"
      system "rvm gemset use ccrb"
    end
  end
end
