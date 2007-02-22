---
title: Rake Tasks
inMenu: false
---

h1. Default Rake targets

By default, CC.rb assumes that your project is a "Rails":http://rubyonrails.org application built by
"Rake":http://rake.rubyforge.org/, and Rakefile is in the root directory of the project. Just running
<code>default</code> Rake task is not good enough, because in a standard Rails application this task needs an
up-to-date development database to work. On a continuous build server there is usually no such thing.

Therefore, CC.rb uses the following logic to determine what to build:

1. First, CC.rb loads all *.rake files from [cruise]/tasks/, and then the Rakefile of your_project.
   Then it invokes <code>cc:build</code> task (defined in [cruise]/tasks/cc_build.rake). This task looks at all other
   Rake tasks (defined in your_project), and decides what to do.

2. If there is <code>cruise</code> target, it simply invokes that target.

3. If there is no <code>cruise</code> target, then it will try to prepare the test database by executing
   <code>db:test:purge</code> and <code>db:migrate</code> tasks (if they are defined in your build), then calling
   <code>test</code> target.

p(hint) Unless your Rakefile has already set it to something else, operating system variable RAILS_ENV is set to
        "test" before calling other default Rails tasks. This is to make sure that db: tasks work with the 
        right database environment.

4. Finally, if there is no <code>test</code> target, CC.rb will try to invoke <code>default</code> target.

p(hint). Hint: if you define <code>cruise</code> task in your_project, you should make it dependent on
<code>db:test:purge</code> and <code>db:migrate</code>, and/or whatever is necessary to bring test environment up
to date.

p(hint). Hint: You can configure CruiseControl.rb to build any kind of application. It doesn't need to be Rails.