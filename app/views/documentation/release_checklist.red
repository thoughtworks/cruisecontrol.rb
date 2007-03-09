While creating a new release:

# Did I run all the tests?
# Did I carefully read README and CHANGELOG, then updated them for the release? 
# Particularly, did I move contents fof the CHANGELOG trunk chapter to the (newly created) release chapter?
# Did I change version number in lib/cruisecontrol/version.rb?
# Did I tag the release, using correct naming convention for the tag?
# Did I execute "svn export" from the tag (to get rid of .svn directories)?
# Did I create .zip package on a Windows (with CRLF endline characters) and .tgz package on Linux (with LF endline characters)
# Did I package archives so that unpacking them to '.' creates ./cruisecontrol-X.Y.Z/ directory and places everything inside it?
 RubyForge using correct naming convention?
# Did I write RubyForge announcement in the project news?
# Did I hide in RubyForge File area those old releases that are obsoleted by this one (any old release for now, release candidates later)?
# Did I send the announcement to TW-dynamic-languages? TW-software-dev? ruby-talk? rails-talk? Papa Roy? Friends and family?
# Did I upload up-to-date documentation to the project's web site?
# Did I deploy the released version to cruisecontrolrb.thoughtworks.com?
# Did I do something not included in this checklist? If yes, did I add that something to this list?
