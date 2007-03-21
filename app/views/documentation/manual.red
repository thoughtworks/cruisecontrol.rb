h1. Manual

This is the CruiseControl.rb manual. If you can't find what you're looking for here, make sure to look at the docs
for "plugins":/documentation/plugins or just "contact us":/documentation/contact_us

h1. Files and folders

If CC.rb is unpacked into [cruise] directory , then:

* [cruise]/projects/ is the projects directory.

* [cruise]/projects/your_project/ is a directory for the project called "your_project".

* [cruise]/projects/your_project/work/ is a local copy of your_project's source code. Builder keeps it up to date
  with the source control repository and runs builds against it.

* [cruise]/projects/your_project/build-123/ contains build status file, list of changed files,
  and other "build artifacts" created while building revision 123.

* [cruise]/projects/your_project/cruise_config.rb is builder configuration for your_project.

* [cruise]/config/site_config.rb is the file where you can make centralized changes to the configuration of dashboard
  and all builders.


h1. Site configuration

CruiseControl.rb package includes a file called [cruise]/config/site_config.rb.example. By copying it to
[cruise]/config/site_config.rb, and uncommenting some lines you can change a number of parameters not related to
a specific project. In normal life, your only reason to do it would be configuring SMTP connection, for sending
email notices. See the section on "Build monitoring via email" below. 


h1. Project builder configuration

When you add a project to it, CruiseControl.rb will try to do something reasonable without any configuration.

However, there are things that builder cannot know in advance. For example, who needs to receive an email notice
when the build is broken? The default answer is "nobody", and it may be good enough if you use
"CCTray":http://ccnet.sourceforge.net/CCNET/CCTray.html or have an LCD panel displaying the dashboard on the wall of
your office to monitor the build status.

What if it's not good enough? To make the builder aware of all these other things that you want it to do, you will
have to write them down in a project configuration file.

Rolling your eyes already? Hold on, this is not J2EE deployment descriptors we are talking about. No two pages of
hand-crafted angled brackets just to get started here. A typical project configuration is about 3 to 5 lines of very
simple Ruby. Yes, the configuration language of CC.rb is Ruby.

As you add a project, a configuration file is created for you in [cruise]/projects/your_project/ directory. It's named
cruise_config.rb and almost everything in it is initially commented out. In fact, you can delete it and this will not
change anything. There are two lines not commented out:

<pre><code>Project.configure do |project|
end
</code></pre>

Every cruise_config.rb must have these two lines. All your other configuration goes between them.

You can move cruise_config.rb in [cruise]/projects/your_project/work/ directory. In other words, check it into
Subversion in the root directory of your project. Storing your CI configuration in your project's version control
is usually a smart thing to do.

It is also possible to have two cruise_config.rb files for a project, one in the [cruise]/projects/your_project/
directory, and the other in version control. CruiseControl.rb loads both files, but settings from cruise_config.rb in
[cruise]/projects/your_project/ override those stored in version control. This can be useful when you want to see the
effect of some configuration settings without checking them in, or have some local settings for this installation.

p(hint). Hint: configuration examples below include lines that look like '...' This represents other
         configuration statements that may be in cruise_config.rb. You are not meant to copy-paste those dots into
         your configuration file. If you do, <code>./cruise start</code> will fail to start, saying something about
         syntax error (SyntaxError). Understandably, ... is not a valid Ruby expression.

Since configuration files are written in a real programming language (Ruby), you can modularize them, use
logical statements, and generally do whatever makes sense. For example, consider the following snippet:

<pre><code>Project.configure do |project|
  case project.name
  when 'MyProject.Quick' then project.rake_task = 'test:units'
  when 'MyProject.BigBertha' then project.rake_task = 'cruise:all_tests'
  else raise "Don't know what to build for project #{project.name.inspect}"
  end
end
</code></pre>

h1. What will it build by default?

By default, CruiseControl.rb will search for "Rake":http://rake.rubyforge.org/ build file in your project. Then
it will try to execute <code>cruise</code> task and stop right there, if <code>cruise</code> task is defined in your
build.

p(hint). If you don't want to leave the question "how to build this project?" to CruiseControl's best guesses
         just define <code>cruise</code> task in your build explicitly.

If there is no <code>cruise</code> task anywhere in sight, CruiseControl.rb will try to perform standard
Rails tasks that prepare a test database by deleting everything from it and executing
"migration":http://www.rubyonrails.org/api/classes/ActiveRecord/Migration.html scripts from your_project/db/migrate.
Finally, it will run all your automated tests.

p(hint). WARNING: with Rails projects, it is important that RAILS_ENV does not default to 'production'.
         Unless you want your migration scripts and unit tests to hit your production database, of course.
         CruiseControl.reb clears this environment variable before calling 'cruise' or custom Rake task, and sets
         it to 'test' before calling the defaults.

h1. How can I change what the build does?

<code>cruise</code> may be the task for a quick build, but you may also want to run a long build with all acceptance
tests included. This can be done by assigning the <code>project.rake_task</code> attribute in cruise_config.rb:

<pre><code>Project.configure do |project|
  ...
  project.rake_task = 'Big_Bertha_build'
  ...
end
</code></pre>

p(hint). Hint: When you have two builds for the same projects, and want to run them on the same build server, it
         actually takes more than just a different Rake task. At the very least, you want to have separate databases
         for those two builds. You can achieve this by creating a separate environment and setting RAILS_ENV to it in
         your Rakefile. Copy config/environments/test.rb to config/environments/big_bertha.rb and write something like
         <code>ENV['RAILS_ENV'] = 'big_bertha'</code> as the first line of your <code>Big_Bertha_build</code> Rake task.

p(hint). Hint: Ideally, you'd also want some way to chain builds so that the long build only for a new checkin is
         launched once the short build has finished succesfully. For now, you can achieve something like this with a
         custom scheduler. CruiseControl.rb team intends to provide built-in support for this scenario in some future
         version.

Or you may not want to deal with Rake at all, but build your project by "make":http://www.gnu.org/software/make/,
"Ant":http://ant.apache.org/ or "MSBuild":http://msdn2.microsoft.com/en-us/library/wea2sca5.aspx.
Yes, CC.rb can deal with non-Ruby projects! We are running "JBehave":http://jbehave.org/ build on
our "demo site":http://cruisecontrolrb.thoughtworks.com/builds/JBehave to prove the point.

A custom build command can be set in <code>project.build_command</code> attribute. Modify cruise_config.rb file like
this:

<pre><code>Project.configure do |project|
  ...
  project.build_command = 'my_build_script.sh'
  ...
end
</code></pre>

If <code>project.build_command</code> is set, CC.rb will change current working directory to
[cruise]/projects/your_project/work/, invoke specified command and look at the exit code to determine whether the
build passed or failed.

p(hint) You cannot specify both <code>rake_task</code> and <code>build_command</code> attributes in cruise_config.rb.
        It doesn't make sense, anyway.


h1. What should I do with custom build artifacts?

your_project may have a special build task, producing some output that you want to keep, and see on
the build page.

p(hint). Hint: Code coverage analysis is a good example of custom build output. CruiseControl.rb's own build uses
         "rcov":http://eigenclass.org/hiki.rb. If you drill down into a recent CC.rb build on
         "http://cruisecontrolrb.thoughtworks.com":http://cruisecontrolrb.thoughtworks.com, you can see links
         to test coverage reports.

Before running the build, CC.rb sets OS variable <strong>CC_BUILD_ARTIFACTS</strong> to the directory
where the build artifacts are collected. Make sure that your special task writes its output to that directory, or a
subdirectory under that directory.

The build page includes links to every file or subdirectory found in the build artifacts directory.


h1. Build monitoring via email

<%= render_plugin_doc 'installed/email_notifier.rb' %>

h1. Build notices via instant messaging with Jabber

"Jabber":http://www.jabber.org/ is an open protocol for instant messaging. Jabber messages can be sent to all sorts of
IM systems, including AIM, Google Talk, ICQ, IRC, MSN and Yahoo. CC.rb comes with a Jabber plugin. Look
at [cruise]/builder_plugins/available/jabber_notifier/README for the installation guide and further details.


h1. Build monitoring with CCTray

"CCTray":http://ccnet.sourceforge.net/CCNET/CCTray.html is a utility developed as part of CruiseControl.NET project
that displays an icon in the bottom right corner of the screen. The icon changes its color to red when a build fails,
and back to green when the build is fixed.

CruiseControl.rb can be monitored by CCTray. To connect CCTray to CruiseControl.rb dashboard, start CCTray, right
click on CCTray icon, select Settings..., click on Add button, click on Add Server button, select
"Via CruiseControl.NET Dashboard" option and type http://<cruise_host>:3333 in the text box. Click OK, select
your project, click OK again, close the Settings dialog. Voila, you are monitoring your build with CCTray.

At the time of this writing, CC.rb was tested to work with CCTray 1.2.1
<small>("download":http://downloads.sourceforge.net/ccnet/CruiseControl.NET-CCTray-1.2.1-Setup.exe?modtime=1170786355&big_mirror=0)</small>

p(hint). Hint: CCTRay only works on a Windows desktop.


h1. Build scheduling

By default, the builder polls Subversion every 10 seconds for new revisions. This can be changed by adding the
following line to cruise_config.rb:


<pre><code>Project.configure do |project|
  ...
  project.scheduler.polling_interval = 5.minutes
  ...
end
</code></pre>

What if you want a scheduler with some interesting logic? Well, a default scheduler can be substituted by placing
your own scheduler implementation intpo the plugins directory and writing in cruise_config.rb something like this:

<pre><code>Project.configure do |project|
  ...
  project.scheduler = MyCustomScheduler.new(project)
  ...
end
</code></pre>

After initializing everything, and loading the project (step that includes evaluation of cruise_config.rb), the
builder invokes project.scheduler.run. Project may detect that its configuraton has changed, so a scheduler needs to
know how to recognize that situation.

Look at [cruise]/app/models/polling_scheduler.rb to understand how a scheduler interacts with a project.


h1. Deleting a project

To remove your_project from CruiseControl.rb, kill its builder process and then delete the [cruise]/projects/your_project/
directory.


h1. Troubleshooting and support

Beware, at the time of this writing, CC.rb is very young and not very stable. Good news is that it's simple (much, much
simpler than other CruiseControl incarnations). The dashboard is just a small Rails app, and the builder is little
more than a dumb, single-threaded Ruby script. Therefore, it's easy to debug. So, you are your own support hotline.
Don't forget to send us patches, please!

OK, that was the pep talk. If you have an issue that you cannot fix on your own, subscribe to mail list
cruisecontrolrb-users@rubyforge.org and ask for help.

h1. Documentation that we haven't written yet

We should write about ways to run CC.rb as a service on various platforms, write about various troubleshooting
techniques, document builder plugins etc.

p(hint). Hint to would-be contributors: documentation patches will be appreciated as highly as, if not higher than,
source patches.
