h1. Getting Started

<div id="letter_shadow">
<div class="letter">
*Dear build -monkey- -master- artist,*

We created CruiseControl.rb so that you can kick ass.

We want you to have basic continuous integration up and running 10 minutes after reading this page.
After that, we want you to find that the tool looks good, does what you expect, and basically just
works. Finally, when you need to do something unusual, we want you to be surprised by how easy that was, too.

In short, we want you to *love* CruiseControl.rb.

Very truly yours,<br/>
<br/>
CruiseControl.rb team<br/>
ThoughtWorks<br/>

<small>P.S. We also want to know if we somehow fall short of these goals.</small>
</div>
</div>

h1. Basics

CruiseControl.rb consists of two pieces: a builder and a dashboard.

A *builder* is a daemon process that polls your source control repository every once in a while looking for new revisions.

When someone performs a check in, the builder will:

# detect it
# update its own copy of the project
# run the build
# notify interested parties of the build's outcome

The *dashboard* is a web application allows you to monitor the status of project builds and help you troubleshoot failures.

Each installation of CruiseControl.rb may have multiple projects and multiple builders (one per project). There may
also be multiple installations of CruiseControl.rb per computer.

h1(#install-prerequisites). Prerequisites

* "Ruby":http://www.ruby-lang.org/en/ 1.8.7. (Note: at the time of this writing CruiseControl.rb does not work with Ruby 1.8.6).
* A supported SCM tool, such as:
** "Subversion":http://subversion.tigris.org/ client 1.4 or later
** "Git":http://git-scm.com/
** "Mercurial":http://mercurial.selenic.com/wiki/
** "Bazaar":http://bazaar-vcs.org/
* The Ruby executable and the associated executable for which SCM you are using must both be in your PATH.

h1. Assumptions and limitations

* Dashboard and all builders need to run on the same computer.

h1(#installation). Installation

Follow these directions or watch our "5 minute install":/documentation/screencasts screencast.

1. "Download":http://github... and unpack CruiseControl.rb.

p(def). Below, we will refer to the place where you unpack it as *$cruise*.

2. From *$cruise*, run <code>./cruise add your_project --source-control [git|hg|svn] --repository [location of your source control repository]</code>.

p(def hint). Hint: Optionally, you can specify username and password by adding <code> --username [your_user] --password 
    [your_password]</code> to the command.

p(def hint). Hint: You can also tell CCRB to build a particular branch by using <code> --branch [branch name]</code> 
    (Git and Mercural only).

p(def). This creates a <code>$HOME/.cruise</code> directory (<code>%USERPROFILE%\.cruise</code>
    if you are on Windows), and that is where CruiseControl.rb keeps its data, and then checks out your_project
    from the subversion URL you provided to <code>$HOME/.cruise/projects/your_project/work/</code>.

p(def). Documentation refers to $HOME/.cruise/ as *$cruise_data*.

p(def hint). Hint: A common Subversion mistake is to provide the root of project's repository instead of the trunk.
    If you do, CruiseControl.rb will check your project out to *$cruise_data*/projects/your_project/work/trunk/,
    and so will not be able to locate your project's build script or Rakefile.

3. From *$cruise*, run <code>./cruise start</code>.

p(def hint). Hint: This starts both the dashboard and any builder(s). By default, the dashboard is bound to port 3333;
    if you want to run your server on a different port, just type <code>./cruise start -p [port]</code>.

4. Browse to "http://localhost:3333":http://localhost:3333. 

p(def). At this point you should see a page with the CruiseControl.rb logo and one project--the one you've just configured. 
    This is the dashboard, and it displays all your currently-configured projects and their build status.  If your build is green, 
    you're done, although you should double check that it's doing what it should be by clicking on the project name and looking 
    at the build log for the last build.  If it's failing or otherwise misbehaving, go on to step 5.
   
5. Figure out what's making your build fail and fix it. Most often this involves running <code>rake test</code> in your project and examining
  the output.

p(def hint). Hint: Often, the easiest way to diagnose build failures is navigate to 
    *$cruise_data*/projects/_your_project_/work/ and run the same command that CruiseControl.rb is 
    running. You'll be able to monitor the logs for your app in real time rather than relying on the archived build
    logs available by default.

6. Press the "build now" button on the "Dashboard":http://localhost:3333 to rebuild your project. Or, just commit more code and wait for
  CruiseControl.rb to rebuild it automatically!

p(def). This should build your_project and place build outputs into *$cruise_data*/projects/your_project/build-[revision-number]/

p(def hint). Hint: Monitor log/your_project_builder.log for any signs of trouble. Try to check in a change to
    your_project and see if the builder can detect and build it.  Check your_project status in the dashboard.

p(def hint). Hint: <code>./cruise help</code> displays a list of commands, <code>./cruise help [command]</code>
    displays options available for each command.

<div class="next_step">Next step: read the "manual":/documentation/manual.</div>
