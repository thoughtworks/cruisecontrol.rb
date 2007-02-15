<% @title = 'Welcome to CruiseControl.rb' %>

h2. What is this?

CruiseControl.rb is a continuous integration tool. Its basic purpose in life is to alert members of a software project
when one of them checks something into source control that breaks the build.

CC.rb is easy to install, pleasant to use and simple to hack. It's written in "Ruby":http://www.ruby-lang.org/en/.

p(hint). Hint: "Martin Fowler":http://martinfowler.com/ explains the how and why of Continuous Integration in this
         "article":http://martinfowler.com/articles/continuousIntegration.html.

h2. Feature list

* Can be installed in 10 minutes.

* Works out of the box with a regular "Ruby":http://www.ruby-lang.org/en/ or "Ruby on Rails":http://rubyonrails.org
  project. No configuration necessary.

* Web-based dashboard, convenient, useful and pretty.

* When a build is broken or fixed, notifies users via email, instant messaging or
  "CCTray":http://ccnet.sourceforge.net/CCNET/CCTray.html.

* Track build status of your favourite projects via RSS/Atom feeds.

* Jump to the code causing a build error in one click.

* Displays custom build artifacts. No configuration necessary.

* Can interoperate with any build tool that can be invoked through command line and returns a non-zero exit code if
  the build fails. Like:
** nant
** ant
** etc...

* Extendable through builder plugins, custom build schedulers and other configuration options.

* Infinitely hackable thanks to publicly available source code and Ruby open classes.

* Free as in "free beer".

h2. Demo site

"Here":http://cruisecontrolrb.thoughtworks.com/ is a public CruiseControl.rb instance building itself and some other open-source projects. 

<div class="next_step">Next step: "download":download.html CruiseControl.rb</div>