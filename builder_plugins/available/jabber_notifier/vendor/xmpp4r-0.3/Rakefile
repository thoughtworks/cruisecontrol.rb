require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake'
require 'find'

begin
  require 'rubygems'
  require 'rcov/rcovtask'
  RCOV = true
rescue LoadError
  RCOV = false
end


# Globals

PKG_NAME = 'xmpp4r'
PKG_VERSION = '0.3'

PKG_FILES = ['ChangeLog', 'README', 'COPYING', 'LICENSE', 'setup.rb', 'Rakefile', 'UPDATING']
Find.find('lib/', 'data/', 'test/', 'tools/') do |f|
	if FileTest.directory?(f) and f =~ /\.svn/
		Find.prune
	else
		PKG_FILES << f
	end
end


# Tasks

task :default => [:package]

Rake::TestTask.new do |t|
	t.libs << "test"
	t.test_files = FileList['test/tc_*.rb']
end

Rake::RDocTask.new do |rd|
  f = []
  require 'find'
  Find.find('lib/') do |file|
    # Skip hidden files (.svn/ directories and Vim swapfiles)
    if file.split(/\//).last =~ /^\./
      Find.prune
    else
      f << file if not FileTest.directory?(file)
    end
  end
  f.delete('lib/xmpp4r.rb')
  # hack to document the Jabber module properly
  f.unshift('lib/xmpp4r.rb')
  rd.rdoc_files.include(f)
  rd.options << '--all'
  rd.options << '--diagram'
  rd.options << '--fileboxes'
  rd.options << '--inline-source'
  rd.options << '--line-numbers'
  rd.rdoc_dir = 'rdoc'
end

task :doctoweb => [:rdoc] do |t|
   # copies the rdoc to the CVS repository for xmpp4r website
	# repository is in $CVSDIR (default: ~/dev/xmpp4r-web)
   sh "tools/doctoweb.bash"
end

Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
	p.need_tar = true
	p.package_files = PKG_FILES
	p p.package_files
end

if RCOV
	Rcov::RcovTask.new do |t|
		#t.test_files = FileList['test/tc_*.rb'] + FileList['test/*/tc_*.rb'] - ['test/tc_streamError.rb']
		t.test_files = ['test/ts_xmpp4r.rb']
	end
end

# "Gem" part of the Rakefile
begin
	require 'rake/gempackagetask'

	spec = Gem::Specification.new do |s|
		s.platform = Gem::Platform::RUBY
		s.summary = "Ruby library for Jabber Instant-Messaging"
		s.name = PKG_NAME
		s.version = PKG_VERSION
		s.requirements << 'none'
		s.require_path = 'lib'
		s.autorequire = 'xmpp4r'
		s.files = PKG_FILES
		s.description = "Ruby library for Jabber Instant-Messaging"
	end

	Rake::GemPackageTask.new(spec) do |pkg|
		pkg.need_zip = true
		pkg.need_tar = true
	end
rescue LoadError
end
