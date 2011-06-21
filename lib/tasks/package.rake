load Rails.root.join("cruisecontrolrb.gemspec")

task :package => ["package:gem"]

namespace :package do
  def gem_file
    if gem_spec.platform == Gem::Platform::RUBY
      "#{gem_spec.full_name}.gem"
    else
      "#{gem_spec.full_name}-#{gem_spec.platform}.gem"
    end
  end

  def package_dir
    "pkg"
  end

  def gem_spec
    GEMSPEC
  end

  task :gem => :prepare do
    Gem::Builder.new(gem_spec).build
    verbose(true) { mv gem_file, "#{package_dir}/#{gem_file}" }
  end

  desc "Remove all existing packaged files."
  task :clean do
    verbose(true) { rm_f package_dir }
  end

  desc "Install all dependencies using Bundler's deployment mode."
  task :prepare => :clean do
    system "bundle install --deployment"
  end
end
