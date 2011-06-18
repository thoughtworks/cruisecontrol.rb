h2. What is a plugin?

CruiseControl.rb uses a plugin mechanism to extend itself and to allow others to extend it.  
Click on one of the above plugins to see the docs about that plugin.

h2. Installing / uninstalling a plugin

All installed plugins are found in the *$cruise_data*/builder_plugins/ directory.
To install a plugin, all you need to do is move it into this directory and restart CC.rb.  To uninstall, 
simply delete it.

For your convenience, additional plugins are distributed in *$cruise*/lib/builder_plugins. You should see them
appear in the list at the top of this page.

h2. Writing a plugin

Plugins are event based. They listen to events that a project fires as it is built. Some of the events include things
like:

* polling_source_control
* build_requested
* build_started
* build_finished
* build_broken
* build_fixed
* build_loop_failed

For the complete list, look at the project.rb file in the codebase.

Look at the existing plugins for examples of what you can do.  For example, this plugin would simply print a message
to the console when the build failed.


  class MinimalConsoleLogger
    def initialize(project)
    end

    def build_loop_failed(error)
      puts "Build loop failed"
      puts "#{error.class}: #{error.message}"
      ...
    end
  end

  Project.plugin :minimal_console_logger

That's it.  That's all the code you need.  Make sure you add your plugin to the project at the end of your file.
Aside from that, the "magic" is just in naming your methods the names of project events. Your method with the same
name will then be called when the events are fired.

If you need a more complicated plugin, they can also be in the form of a directory, see the Jabber plugin as an example.

h2. After you write your plugin

"Send":contributing it to us if you think it might be useful to someone else.
To document it, simply put Textile comments on the top of the file or in the README if it's a directory.
