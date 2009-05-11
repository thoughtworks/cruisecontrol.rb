
== Code coverage analysis automation with Rake

Since 0.4.0, <tt>rcov</tt> features a <tt>Rcov::RcovTask</tt> task for rake
which can be used to automate test coverage analysis.  Basic usage is as
follows:

 require 'rcov/rcovtask'
 Rcov::RcovTask.new do |t|
   t.test_files = FileList['test/test*.rb']
   # t.verbose = true     # uncomment to see the executed command
 end

This will create by default a task named <tt>rcov</tt>, and also a task to
remove the output directory where the XHTML report is generated.
The latter will be named <tt>clobber_rcob</tt>, and will be added to the main
<tt>clobber</tt> target.

=== Passing command line options to <tt>rcov</tt>

You can provide a description, change the name of the generated tasks (the
one used to generate the report(s) and the clobber_ one) and pass options to
<tt>rcov</tt>:

 desc "Analyze code coverage of the unit tests."
 Rcov::RcovTask.new(:coverage) do |t|
   t.test_files = FileList['test/test*.rb']
   t.verbose = true
   ## get a text report on stdout when rake is run:
   t.rcov_opts << "--text-report"  
   ## only report files under 80% coverage
   t.rcov_opts << "--threshold 80"
 end

That will generate a <tt>coverage</tt> task and the associated
<tt>clobber_coverage</tt> task to remove the directory the report is dumped
to ("<tt>coverage</tt>" by default).

You can specify a different destination directory, which comes handy if you
have several <tt>RcovTask</tt>s; the <tt>clobber_*</tt> will take care of
removing that directory:

 desc "Analyze code coverage for the FileStatistics class."
 Rcov::RcovTask.new(:rcov_sourcefile) do |t|
   t.test_files = FileList['test/test_FileStatistics.rb']
   t.verbose = true
   t.rcov_opts << "--test-unit-only"
   t.output_dir = "coverage.sourcefile"
 end
 
 Rcov::RcovTask.new(:rcov_ccanalyzer) do |t|
   t.test_files = FileList['test/test_CodeCoverageAnalyzer.rb']
   t.verbose = true
   t.rcov_opts << "--test-unit-only"
   t.output_dir = "coverage.ccanalyzer"
 end

=== Options passed through the <tt>rake</tt> command line

You can override the options defined in the RcovTask by passing the new
options at the time you invoke rake. 
The documentation for the Rcov::RcovTask explains how this can be done.
