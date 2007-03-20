<% @sidebar = "sidebar_contributing" %>

h1. Contributing

<em>Contributing to CruiseControl.rb boosts your self-esteem, improves your karma, looks good on your CV and generally
makes the world a happier place.</em>

You can help in four different ways:
* <a href="#report">report bugs</a>
* <a href="#plugins">create and publish your own plugins</a>
* <a href="#patches">fix bugs and submit patches</a>
* <a href="#documentation">improve documentation</a>

h2. <a name="report">Report bugs</a>

CruiseControl.rb uses a public "JIRA bug tracker":http://jira.public.thoughtworks.org/browse/CCRB to keep track of bugs,
patches, ideas and development stories.

Before you can submit a bug, you need to
"create a JIRA account":http://jira.public.thoughtworks.org/secure/Signup!default.jspa for yourself. This way we protect
the tracker against spam and make sure that we can get in touch with you if we have questions (or answers).

Please try to be as specific as possible about the symptoms and likely root causes of the problem, include
screenshots, stack traces, quotes from log files or any other relevant information. Do not neglect
<strong>"reading the fine manual":/documentation/manual</strong>, and consulting the
"troubleshooting guide":/documentation/troubleshooting for some useful debugging / evidence gathering techniques.

Also, please try to make sure that the problem is in CruiseControl.rb, not in your build or CI configuration. It can be
quite embarrassing to go through a long chain of emails, and learn at the end of it that it was your problem and you
could have easily figured it out yourself.

h2. <a name="plugins">Create plugins</a>

CruiseControl.rb design philosophy can be summarized as "be simple, and people will come to you". Of course, many
an open-source project started this way, and ended up as a truckload of half-heartedly implemented features. We have no
intention whatsoever to fall into that trap.

This is why CruiseControl is trying to satisfy the basic needs of its primary audience (which is small to medium size
Ruby or Rails projects), while providing enough opportunity for extending and hacking the tool without affecting the
sweet simplicity of the core codebase.

Ruby, of course, is an interpreted language with open classes that lets you do anything you want.
Remember: with great powers come great dangers. The next version of CruiseControl.rb may
simply be incompatible with your black belt hackery. Be wise and constrain yourself to interface points
designed for pluggability.

CruiseControl.rb has a few of these.

h3. Dashboard plugins

Dashboard is a regular Rails application, that can be extended through the regular
Rails
"plugins":http://www.agilewebdevelopment.com/plugins/index
"infrastructure.":http://www.tutorialized.com/tutorial/HOWTO-Make-a-Rails-Plugin-From-Scratch/19055
"Enough said.":http://nubyonrails.com/articles/2006/05/04/the-complete-guide-to-rails-plugins-part-i

h3. Builder plugins

While checking source control for new revisions, building, or handling errors, a builder generates events. Anyone can
write a listener for those events.

<p>To know the types of events a builder sends to its listeners, look at implementation and usages of
<code>Project#notify()</code>
method.</p>

For an example of a working plugin, look at builder_plugins/installed/email_notifier.rb or
builder_plugins/available/jabber_notifier. Note that a plugin can be implemented as a single file, or a
directory (containing init.rb). Either way, the file or directory name should match the class name of the listener
class, and the plugin should be placed in builder_plugins/installed directory.

It would be good to have more documentation here, as well as some guarantees about published API for plugins, but it's
too early to make such commitments. Let's build some great plugins, and see what kind of API evolves in the process.
It's a fair bet that build_finished, build_fixed and build_broken will always be there, have access to
Build and Project instances, and know location of the build artifacts directory for the build in question.

h3. Custom Rake tasks

Surely, if there is a CI tool for Ruby, its capabilities can be greatly enhanced by writing cool Rake tasks and
sharing them with the world.

For example, how about deploying an app to another box via Capistrano, running a battery of Selenium tests against it,
then pulling back test results and placing them in CC_BUILD_ARTIFACTS directory?

Or perhaps a much simpler task that is invoked in the end of a successful unit test build, and creates a "build now"
request for the Big Bang Selenium build described above?

h3. Custom schedulers

Scheduler is an object responsible for telling a Project when to build itself.
At the moment, we only have one kind of a scheduler: a PollingScheduler, which simply tells the builder every so often
to check if source control has new revisions. You can write your own scheduler and inject it into the project through
a configuration file: <code>project.scheduler = AstrologyAwareScheduler.new(current_phase_of_the_moon)</code>

h2. <a name="patches">Submit patches</a>

We absolutely love receiving bug reports. Who doesn't, after all? But what can make us really happy is a bug
report coming with a patch that fixes the bug and adds unit tests to prevent it from ever happening again.
Contributing a well packaged patch that is accepted into the codebase places your name for posterity in
CruiseControl.rb Eternal Hall of Fame, aka the Contributors section of README.

<em>Official Standard Procedure for the Submission of Patches</em> is hereby defined as follows:

1. Check out the latest source from Subversion repository:<br/>

<pre><code>    svn co svn://rubyforge.org/var/svn/cruisecontrolrb</code></pre>

2. Run the build, make sure that it passes: <code>rake</code>

3. Make changes to the source. Don't forget the unit tests.

4. Run the build again, make sure that it still passes.

p(hint). Besides, your tests should not leave any by-products in the file system. If you need to create a file in your
         test, use <code>in_sandbox()</code> or <code>with_sandbox_project()</code> test helpers.

5. Check that Subversion is fully aware of files you added/deleted/renamed : <code>svn stat</code>

6. Create a patch: <code>svn diff > patch_to_fix_global_warming.diff</code>

7. Login to JIRA

8. Create a new issue, prefix the summary with the word [PATCH].

9. Keep in touch by monitoring the issue. Think about joining the
   <%= link_to_developers_mailing_list 'cruisecontrolrb-developers mailing list'%>.

Also, when we're ready to apply the patch, we'll send you an e-mail that looks like "this":contributors_agreement.html 
which we'll need a reply to for legal reasons.

h2. <a name="documentation">Improve documentation</a>

Believe it or not, but we value contributions to end user documentation as much as (if not more than) we value patches.

Documentation for CruiseControl.rb is included in the release package, as files under
the [cruise]/app/views/documentation directory. When you connect to CruiseControl.rb dashboard running on your computer
and click the Documentation link in the top right corner, its the content of those files that you see.

Packaging documentation with release makes sure that you are always looking at documentation for the same version
that you are running. It also makes it easy to submit documentation patches. Simply follow the aforementioned 
<em>Procedure</em> for source code patches.

The *.red files are written in a mixture of "Textile":http://hobix.com/textile and HTML markup. The best way to edit
these files is to run CruiseControl.rb dashboard from your local checked out copy of the trunk, in development mode:

<code>./cruise start -e development</code>.

Any change that you make to a documentation file can be seen in the
browser as soon as you hit the Refresh button.


h2. Copyright considerarions

CruiseControl.rb is developed by "ThoughtWorks":http://www.thoughtworks.com.
ThoughtWorks is an IT consultancy, and we built this tool primarily because our own project
teams need it (these days, we do a lot of Ruby work).

It is distributed under a free open-source "license":/documentation/license. However, ThoughtWorks wants to ensure
that ownership of the codebase remains clear. So, if you want to contribute code to CruiseControl.rb, and you don't work
for ThoughtWorks (by the way, is there any good reason why you don't?), we will ask you to share ownership of your
contributions to us. This is not some sort of evil world domination scheme, just a legal precaution. Apache Software
Foundation, in fact, does "something similar":http://www.apache.org/licenses/icla.txt.
