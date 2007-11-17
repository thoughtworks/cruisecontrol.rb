h1. Source Control

Cruise Control currently ships with only Subversion support.

h1. Configuring Subversion

If you want to configure subversion, you can do it in your cruise_config.rb file.  

<pre><code>
Project.configure do |project|
  project.source_control = Subversion.new
end
</code></pre>

Since Subversion is the default, you shouldn't have to specify this.  However, you might want to in order to change the default settings.

By default cruise checks externals for changes.  If you don't want it to, you can turn it off like

<pre><code>
Project.configure do |project|
  project.source_control = Subversion.new :check_externals => false
end
</code></pre>

h1. Adding Other Source Controls

p(hint). We have NOT actually tested this.  However, we've thought a lot about it, hopefully enough to give you a good place to start.

To use another source control system, you will need to implement the "source_control" interface Subversion does, it will be something like (check the subversion.rb for the uptodate interface) :

<pre><code>
  #you won't need checkout till we add support for automatic checkout from ./cruise add
  checkout(target_directory, revision = nil)  
  latest_revision(project)
  revisions_since(project, revision_number)
  update(project, revision = nil)
</code></pre>

you should be able to create a project directory in

<pre><code>
  CRUISE/projects/PROJECT_NAME
</code></pre>

and in that project directory, create a cruise_config.rb file that has something like this in it :

<pre><code>
Project.configure do |project|
  project.source_control = Perforce.new(:user => 'cruise', :password => 'something cute')
end
</code></pre>

where you replace "Perforce" with your source control class.  for now, you'll also have to manually checkout your project to

<pre><code>
  CRUISE/projects/PROJECT_NAME/work
</code></pre>

However, once we support a couple different source controls, we should add a flag to "./cruise add ..." that will let you specify which to use as well as options for it.

Anyway, that should do it.  Try it and let us know how it goes!