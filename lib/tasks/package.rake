require 'tasks/rails_in_a_war'

task :package => %w(package:clean package:gem package:jar)

namespace :package do
  task :jar => %w(
    package:jar:clean
    package:jar:compile
    package:jar:main_jar
    package:jar:create_gem_dependency_list
    package:jar:package
  )

  task :gem => %w(
    package:gem:clean
    package:gem:package
  )

  def package_dir
    Pathname.new("pkg")
  end

  desc "Remove all existing packaged gems."
  task :clean do
    verbose(true) { package_dir.rmdir rescue nil }
    verbose(true) { package_dir.mkdir rescue nil }
  end
end
