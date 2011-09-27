task :package => ["package:gem"]

namespace :package do
  def package_dir
    "pkg"
  end

  def gem_file
    Pathname.glob("*.gem").first
  end

  desc "Package CruiseControl.rb as a gem."
  task :gem => :prepare do
    system "gem build cruisecontrolrb.gemspec"
    verbose(true) { gem_file.rename(package_dir) }
  end

  desc "Remove all existing packaged files."
  task :clean do
    verbose(true) { rm_f package_dir }
  end

  desc "Install all dependencies using Bundler's deployment mode."
  task :prepare => :clean

  namespace :gem do
    task :test => "package:gem" do
      system "rvm gemset create ccrb-test"
      system "rvm gemset use ccrb-test"
      system "rvm --force gemset empty ccrb-test"

      puts Pathname.glob("#{package_dir}/*.gem").inspect
      gem_file = Pathname.glob("#{package_dir}/*.gem").first
      system "gem install #{gem_file}"
      system "cruise start"
      system "rvm gemset use ccrb"
    end
  end
end
