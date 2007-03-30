h1. FAQ

If the answer to your question isn't here, please email the "users list":/documentation/contact_us

h2. How does cruise know what to build?

By default we use rake and look for the first of
* "cruise" target
* "db:test:purge", "db:migrate", and "test"
* "default"

see "rake tasks":/documentation/rake_tasks and the "manual":/documentation/manual for more information.

h2. Can I use CC.rb to build a java or c# project?

The answer is a qualified yes.  You should be able to have any command line tool build your project including ant or 
nant or even msbuild.  See the "manual":/documentation/manual for more information.

h2. Can I use CC.rb to build a project with Selenium tests in it?

Yes, you can, although there are some stuff you should pay attention to. See "Working with Selenium":/documentation/selenium 
for detail.

h2. What source control systems do you support?

We currently only support "Subversion":http://subversion.tigris.org/.  We are planning on adding support for
Perforce in the not too distant future.  After that, it depends on what people ask for (and what they 
"contribute":/documentation/contributing)


Have other questions?  Ask us on our <%= link_to_users_mailing_list 'mailing list' %>.