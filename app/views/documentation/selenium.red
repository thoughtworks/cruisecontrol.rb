h1. Working with Selenium

"Selenium":http://www.openqa.org/selenium is a test tool for web applications. Selenium tests run directly in a 
browser, just as real users do. CruiseControl.rb is able to work with Selenium. There's a checklist before you
build a project has Selenium tests in it:

* GUI environment
* web server
* artifacts destination

h2. GUI Environment

Selenium tests run in Internet Explorer, Mozilla and Firefox -- that means it requires a GUI environment. In 
other words, your build must be in an X session (if you're using POSIX). Windows users are fortunate: all processes
can kick off browsers.


h2. Web Server

The application-under-test (AUT) needs to be hosted in a web server (and/or application server). You have to start
the server in your build script, execute Selenium tests, then shutdown the server afterwards. 

For Rails applications, Selenium tests often written with "Selenium on Rails":http://www.openqa.org/selenium-on-rails .
In order to run the tests in continuous integration build, you just need:

* <code>mongrel_rails start -d -etest</code>
* <code>rake test:acceptance</code>
* <code>mongrel_rails stop</code>

If you don't have "mongrel":http://mongrel.rubyforge.org installed, or if you are in Windows (which does not 
support <code>-d</code> option of mongrel_rails), or if you are not using Selenium on Rails, you have to figure
out solution by yourself. 


h2. Artifacts Destination

You may want to copy Selenium reports to build artifacts directory, so that you can check the test result via Dashboard.
Selenium on Rails puts the reports in <code>$RAILS_ROOT/log/selenium</code> directory. You can copy them to build 
artifacts directory (please check "What should I do with custom build artifacts?" section in our 
"manual":http://cruisecontrolrb.thoughtworks.com/documentation/manual page). You just need do following in your
<code>cruise</code> Rake task:

<pre><code>
task :cruise do
  out = ENV['CC_BUILD_ARTIFACTS']
  system "mv log/selenium/* #{out}/"
end
</code></pre>