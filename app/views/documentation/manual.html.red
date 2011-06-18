h1. Manual

This is the CruiseControl.rb manual. If you can't find what you're looking for here, make sure to look at the docs
for "plugins":/documentation/plugins or just "contact us":/documentation/contact_us.

h1. Table of Contents

* <a href="#files_and_folders">Files and folders</a>
* <a href="#site_configuration">Site configuration</a>
* <a href="#project_builder_configuration">Project builder configuration</a>
* <a href="#default_build_tasks">Default build tasks</a>
* <a href="#changing_the_build_command">Changing the build command</a>
* <a href="#handling_custom_build_artifacts">Handling custom build artifacts</a>
* <a href="#build_scheduling">Build scheduling</a>
* <a href="#deleting_a_project">Deleting a project</a>
* <a href="#build_chaining_and_triggers">Build chaining & triggers</a>
* <a href="#environment_variables">Environment variables</a>
* <a href="#remote_builds">Remote builds</a>
* <a href="#performing_a_clean_checkout">Performing a clean checkout</a>
* <a href="#troubleshooting_and_support">Troubleshooting and support</a>

h1(#files_and_folders). Files and folders

* *$cruise* is how this documentation refers the directory where CC.rb itself has been unpacked or checked out.

* CC.rb places all of its project, plugin, and configuration data in $HOME/.cruise (%USERPROFILE%\.cruise on Windows).
  This documentation refers to this directory as *$cruise_data*.

* *$cruise_data*/projects/your_project/ is the directory where CC.rb will place the data for the project called "your_project".

* *$cruise_data*/projects/your_project/work/ is a local copy of your_project's source code. Builder keeps it up to date
  with the source control repository and runs builds against it.

* *$cruise_data*/projects/your_project/build-123/ contains a build status file, a list of changed files,
  and other "build artifacts" created while building revision 123.

* *$cruise_data*/projects/your_project/cruise_config.rb contains the build configuration for your_project.

* *$cruise_data*/config/site_config.rb is the file where you can make centralized changes to the configuration of the dashboard
  and all builders.

h1(#site_configuration). Site configuration

p. The CruiseControl.rb package includes a file called *$cruise*/config/site_config.rb.example. By copying it to
*$cruise*/config/site_config.rb and uncommenting some lines you can set a number of global configuration settings.
Normally you would only need to do this to configure an SMTP server for email notices. Email is configured using Rails'
ActionMailer component and accepts its standard configuration settings.


h1(#project_builder_configuration). Project builder configuration

If you don't provide a Cruise configuration for your project, CC.rb will try to make some reasonable guesses about how
to build your project, particularly if it's a Ruby application. (See <a href="#default_build_tasks">Default build tasks</a> below.)

However, there are only a few configuration settings that CC.rb can guess at. Specific projects will require more advanced configuration
if you need to add email notification recipients, configure plugins, or otherwise tweak your build run. A typical project configuration 
in CC.rb is about 3 to 5 lines of very simple Ruby.

When you first add a project, a configuration file called <code>cruise_config.rb</code> is created for you in the 
*$cruise_data*/projects/your_project/ directory. It contains a number of comments, but two lines are important:

  Project.configure do |project|
  end

Every cruise_config.rb must have these two lines, and all your other configuration goes between them. It's recommended that you check
this file into version control, and if you do then changes made to the configuration will be automatically be picked up by CC.rb the
next time you check in without any additional work required.

Optionally, you can put a configuration file in both places above. CruiseControl.rb loads both files, but settings from the
cruise_config.rb in *$cruise_data*/projects/your_project/ override those stored in your project's root directory.
This can be useful when you want to see the effect of some configuration settings without checking them in, or have some
location-dependent settings.

p(hint). Hint: configuration examples below include lines like '...'. This represents other
         configuration statements that may be in cruise_config.rb. You are not meant to copy-paste those dots into
         your configuration file, as they are not valid Ruby. If you do, <code>./cruise start</code> will fail to start
         due to a syntax error.

Since configuration files are written in a real programming language (Ruby), you can modularize them, use
logical statements, and generally do whatever makes sense. For example, consider the following snippet:

  Project.configure do |project|
    case project.name
    when 'MyProject.Quick' then project.rake_task = 'test:units'
    when 'MyProject.BigBertha' then project.rake_task = 'cruise:all_tests'
    else raise "Don't know what to build for project #{project.name.inspect}"
    end
  end

p(hint). Hint: Use code like above to source-control configuration of multiple CruiseControl.rb projects building the same codebase.

h1(#default_build_tasks). Default build tasks

By default, CC.rb will assume that you are building a Ruby project, load your Rakefile, and look for the <code>cruise</code>, 
<code>test</code>, and <code>default</code> (what happens when you just type <code>rake</code> with no arguments) tasks,
in that order, and execute the first one it finds.

Note that Rails provides you with an automatic <code>test</code> task when you first create your project. The behavior
for that task is documented here.

p(hint). WARNING: with Rails projects, it is important that RAILS_ENV does not default to 'production'.
         Unless you want your migration scripts and unit tests to hit your production database, of course.
         CruiseControl.reb leaves this variable unchanged when invoking 'cruise' or other custom Rake task, and sets
         it to 'test' before invoking the defaults.


h1(#changing_the_build_command). Changing the build command or Rake task

<code>cruise</code> may be the task for a quick build, but you may also want to run a long build with all acceptance
tests included. This can be done by assigning the <code>project.rake_task</code> attribute in cruise_config.rb:

  Project.configure do |project|
    ...
    project.rake_task = 'big_bertha_build'
    ...
  end

p(hint). Hint: Be careful when defining additional build tasks. If two builds share the same <code>RAILS_ENV</code> value
         then they will operate against the same database, which means that if two builds run simultaneously there is
         a chance that they will interfere with each other. You can avoid this issue this by creating a separate environment 
         and making sure that the Rake task for your build sets the <code>RAILS_ENV</code> value to that environment in your
         Rake task. Copy config/environments/test.rb to config/environments/big_bertha.rb, add a :big_bertha_init
         Rake task with <code>ENV['RAILS_ENV'] = 'big_bertha'</code> in it, and put it in the beginning of
         <code>:big_bertha_build</code> list of depenedencies.

p(hint). Hint: Ideally, you'd also want some way to chain builds so that the long build for a new checkin is only
         launched once the short build has finished succesfully. CruiseControl.rb provides support for this option through
         the <code>triggered_by</code> project build configuration feature; see 
         <a href="#build_chaining_and_triggers">Build Chaining & Triggers</a>.

CC.rb may be written in Ruby on Rails, but you don't need to be using Ruby and Rake in order to take advantage of it.
Other build tools like "make":http://www.gnu.org/software/make/,
"Ant":http://ant.apache.org/ and "MSBuild":http://msdn2.microsoft.com/en-us/library/wea2sca5.aspx are also supported--
really, any command that can return a success or failure status code.

A custom build command can be set with the <code>project.build_command</code> attribute. Modify cruise_config.rb file like
this:

  Project.configure do |project|
    ...
    project.build_command = 'my_build_script.sh'
    ...
  end

If <code>project.build_command</code> is set, CC.rb will invoke the specified command from the project's work directory
(*$cruise_data*/projects/your_project/work/) and examine the exit code to determine whether the
build passed or failed.

p(hint). Hint: You cannot set both the <code>rake_task</code> and <code>build_command</code> attributes in a a given project configuration.


h1(#handling_custom_build_artifacts). What should I do with custom build artifacts?

Some build tasks generate custom output, like test coverage statistics, that you may want to keep and see on the build page.
CruiseControl.rb supports the integration of that output by setting the <strong>CC_BUILD_ARTFACTS</strong> environment variable
to a directory that's been set aside specifically to collect them. 

If you ensure that your special task writes its output to that directory or a subdirectory of it, then the resulting build artifacts page will automatically include links to every file or subdirectory found in the build artifacts directory.

p(hint). Hint: Code coverage analysis is a good example of custom build output. CruiseControl.rb's own build uses
         "rcov":http://eigenclass.org/hiki.rb. If you drill down into a recent CC.rb build on
         "http://cruisecontrolrb.thoughtworks.com":http://cruisecontrolrb.thoughtworks.com, you can see links
         to test coverage reports.
         
p(hint). Hint: The "metric_fu":http://github.com/jscruggs/metric_fu/tree/master project collects a number of
         helpful Ruby code metrics into a single, easy-to-configure plugin and integrates well with CC.rb.


h1(#build_scheduling). Build scheduling

By default, the builder polls Subversion every 10 seconds for new revisions. This can be changed by adding the
following line to cruise_config.rb:

  Project.configure do |project|
    ...
    project.scheduler.polling_interval = 5.minutes
    ...
  end

What if you want a scheduler with some interesting logic? Well, a default scheduler can be substituted by placing
your own scheduler implementation into the plugins directory and configuring it as follows:

  Project.configure do |project|
    ...
    project.scheduler = MyCustomScheduler.new(project)
    ...
  end


After initializing everything, and loading the project (this step includes evaluation of cruise_config.rb), the
builder invokes project.scheduler.run. A builder must be able to detect when its configuration has changed, or when a 
build is requested by user (by pressing the Build Now button), so a custom scheduler needs to know how to recognize that situation.

Look at *$cruise*/app/models/polling_scheduler.rb to understand how a scheduler interacts with a project.


h1(#deleting_a_project). Deleting a project

To remove your_project from CruiseControl.rb, kill its builder process and then delete the *$cruise_data*/projects/your_project/
directory.


h1(#build_chaining_and_triggers). Build chaining & triggers

CC.rb uses triggers to tell it when to build a project.  Every project is configured, by default, with a ChangeInSourceControl trigger: it builds
when (surprise) it detects a change in a project's source control.

However, you can add additional triggers or replace a trigger entirely.  For example, you can have one project's successful build trigger another project's build with our SuccessfulBuildTrigger.

  project.triggered_by SuccessfulBuildTrigger.new(project, 'indie')

or, in short hand:

  project.triggered_by 'indie'

Why would you want one build to trigger another?  In this instance, maybe our project depends on indie and we want to know if a change to indie breaks our project.

These examples, *added* a SuccessfulBuildTrigger.  We could also *replace* the default trigger by writing

  project.triggered_by = [SuccessfulBuildTrigger.new(project, "fast_build")]

Why wouldn't we want our project to be triggered by a change to it's source code?  In this case, maybe we've separated our project into a fast and slow build.  We could use this to only trigger a slow build if the fast one passes.

h1(#environment_variables). Environment variables

CC.rb can set any custom environment variables that your build requires.  Every project can be configured to build with different environment variables.  For example:

  Project.configure do |project|
    project.environment['DB_HOST'] = 'db.example.com'
    project.environment['DB_PORT'] = '1234'
  end

h2(#ccrb_environment_variables). Special environment variables

CC.rb sets some environment variables when it runs your build, and you can use them inside your build process to tweak it or its output. Currently
there are just three:
* <code>CC_BUILD_REVISION</code> - this is the revision number of the current build, it looks like "5" or "56236"
* <code>CC_BUILD_LABEL</code> - usually this is the same as CC_BUILD_REVISION, but if there is more than one build of a particular revision, it will have a ".n" after it, so it might look like "323", "323.2", "4236.20", etc.
* <code>CC_BUILD_ARTIFACTS</code> - this is the directory which the dashboard looks in.  Any files you copy into here will be available from the dashboard.

h1(#remote_builds). Remote builds

CC.rb can run builds on remote servers.  This is done by sshing to the server in your build command.  For example:

  project.build_command = 'ssh user@server ./run_remotely.sh $CC_BUILD_REVISION'

run_remotely.sh might look something like:

  #/bin/bash
  svn up -r$1
  rake test:integration

Of course you will need to checkout the code on the remote server before running the first build.

Note that CC.rb will still maintain a checkout of the code on the local server, use it to check for modifications and store build results locally.
More robust support for builders on remote servers is expected in release 2.0.


h1(#performing_a_clean_checkout). Performing a clean checkout for each build

CC.rb supports clean checkouts, though they are not the default behavior.  To enable them, you must use the <code>do_clean_checkout</code>
flag together with an optional frequency. Acceptable values are <code>:always</code>, <code>:never</code>, and <code>:every => [duration]</code>.

  project.do_clean_checkout :every => 6.hours

h1(#troubleshooting_and_support). Troubleshooting and support

If you have an issue that you cannot fix on your own, please consider subscribing to our mailing list at cruisecontrolrb-users@rubyforge.org 
and asking for help. Please note, though, that we take great pains to make CC.rb easy to hack, and we encourage you to poke around in the
source code and hack away.

Should you require commercial support, training or consulting around this or other tool, "ThoughtWorks":http://thoughtworks.com/ can 
provide it to you. We also offer a commercial CI product, "Cruise":http://studios.thoughtworks.com/cruise-continuous-integration, through 
ThoughtWorks Studios, our product division.

p(hint). Hint to would-be contributors: documentation patches are as important, if not more so, than code patches, and would be
         gratefully accepted.
