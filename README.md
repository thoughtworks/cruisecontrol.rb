# CruiseControl.rb: Simple Continuous Integration

###Introduction

[CruiseControl.rb](http://cruisecontrolrb.thoughtworks.com) is a [continuous integration](http://martinfowler.com/articles/continuousIntegration.html) server. It keeps everyone in your team informed about the health and progress of your project.

CC.rb is easy to install, pleasant to use and simple to hack. It's written in Ruby and maintained in their spare time by developers at [ThoughtWorks](http://www.thoughtworks.com), a software development consultancy.

[<img src="https://travis-ci.org/ianheggie/cruisecontrol.rb.png?branch=master" alt="Build Status" />](https://travis-ci.org/ianheggie/cruisecontrol.rb)
[<img src="https://codeclimate.com/github/ianheggie/cruisecontrol.rb.png" alt="Static Code analysis" />](https://codeclimate.com/github/ianheggie/cruisecontrol.rb)
[<img src="https://gemnasium.com/ianheggie/cruisecontrol.rb.png" alt="Dependency Status" />](https://gemnasium.com/ianheggie/cruisecontrol.rb)

### Links

* Documentation: http://cruisecontrolrb.thoughtworks.com/documentation/docs
* Source: http://github.com/thoughtworks/cruisecontrol.rb
* IRC: #cruisecontrol on freenode.
* Download: `git clone git@github.com:thoughtworks/cruisecontrol.rb.git`

### The quick how-to

  $ ./cruise start

This should start CC.rb on port 3333. To add new projects, there's a GUI interface, or you can use the command line:

  $ ./cruise add [project-name] -r [repository] -s [svn|git|hg|bzr]

### License:

* Apache Software License 2.0

(C) ThoughtWorks Inc. 2007 - 2013
