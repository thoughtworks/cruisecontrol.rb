h1. Getting Notified

Let's admit it, the main duty of continuous integration tool is to -annoy- notify developers when the build is broken. CruiseControl.rb is capable of delivering carefully measured doses of annoyance on demand, through a variety of communication channels, including email, instant messaging, RSS feeds etc, etc.

h2. E-mail

<%= render_plugin_doc 'installed/email_notifier.rb' %>

h2. CCTray (on windows)

"CCTray":http://ccnet.sourceforge.net/CCNET/CCTray.html is a utility developed as part of CruiseControl.NET project
that displays an icon in the bottom right corner of the screen. The icon changes its color to red when a build fails,
and back to green when the build is fixed.

CruiseControl.rb can be monitored by CCTray. To connect CCTray to CruiseControl.rb dashboard, start CCTray, right
click on CCTray icon, select Settings..., click on Add button, click on Add Server button, select
"Via CruiseControl.NET Dashboard" option and type http://[cruise_host]:3333 in the text box. Click OK, select
your project, click OK again, close the Settings dialog. Voila, you are monitoring your build with CCTray.

At the time of this writing, CC.rb was tested to work with CCTray 1.2.1
<small>("download":http://downloads.sourceforge.net/ccnet/CruiseControl.NET-CCTray-1.2.1-Setup.exe?modtime=1170786355&big_mirror=0)</small>

p(hint). Hint: CCTray only works on a Windows desktop.


h2. CCMenu (on OSX)

"CCMenu":http://ccmenu.sourceforge.net/ displays the project status of CruiseControl continuous integration servers as an item in the Mac OS X menu bar. Or in other words, CCMenu is to OS X what CCTray is to Windows.

CCMenu has explicit support for CC.rb built in, and it's quite easy to add projects and even force builds on them.   

Keep in mind, when adding a project, the server name is something like http://localhost:3333/.  And it should look something like

!/images/documentation/ccmenu.png!

h2. Monitoring by other means

Dashboard has RSS feeds both for the entire site and each project individually. This is useful for watching the build status of projects that 
you are not actively working on. 

Version 1.1 also has plugins to get notifications via Jabber (instant messaging), and Growl. Read about these and other plugins in 
"plugin documentation":/documentation/plugins. It's also quite easy to write your own notification plugin if needed.
