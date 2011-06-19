h1. Source Control

CruiseControl.rb currently ships with support for <a href="#subversion">Subversion</a>, 
<a href="#git">Git</a>, <a href="#mercurial">Mercurial</a> and <a href="bazaar">Bazaar</a>. By default 
you should not need to configure any settings for your SCM of choice, though you may choose to if you wish.

h1(#subversion). Configuring Subversion

Subversion may be explicitly configured in your cruise_config.rb file as follows:

  Project.configure do |project|
    project.source_control = SourceControl::Subversion.new :option => value...
  end

Subversion accepts the following configuration options:

* <code>:repository</code>, <code>:username</code>, <code>:password</code> as in standard Subversion
* <code>:interactive</code> sets interactive mode; false by default
* <code>:check_externals</code> tells CC.rb to trigger a build if externals change; true by default
* <code>:path</code> is the location of an empty directory to check your project out into

h1(#git). Configuring Git

Git may be explicitly configured in your cruise_config.rb file as follows:

  Project.configure do |project|
    project.source_control = SourceControl::Git.new :option => value...
  end

Git accepts the following configuration options:

* <code>:repository</code> as in standard Git
* <code>:watch_for_changes_in</code> to tell CC.rb to only monitor for changes in this subdirectory
* <code>:branch</code> to build a particular branch of your Git repository
* <code>:path</code> is the location of an empty directory to check your project out into

h1(#mercurial). Configuring Mercurial

Mercurial may be explicitly configured in your cruise_config.rb file as follows:

  Project.configure do |project|
    project.source_control = SourceControl::Mercurial.new :option => value...
  end

Mercurial accepts the following configuration options:

* <code>:repository</code> as in standard Mercurial
* <code>:branch</code> to build a particular branch of your Mercurial repository
* <code>:path</code> is the location of an empty directory to check your project out into

h1(#bazaar). Configuring Bazaar

Bazaar may be explicitly configured in your cruise_config.rb file as follows:

  Project.configure do |project|
    project.source_control = SourceControl::Bazaar.new :option => value...
  end

Bazaar accepts the following configuration options:

* <code>:repository</code> as in standard Mercurial
* <code>:path</code> is the location of an empty directory to check your project out into
