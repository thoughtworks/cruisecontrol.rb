h1. Troubleshooting

p(hint). This section needs users contributions more than any other. Authors know very well how everything works, and
what the assumptions/limitations are. When something goes wrong, we simply dive into the source code.
Oddly enough, it means that we don't have much troubleshooting experience! At least, not of the kind that can be useful
to a casual reader.

h2. Builder with <code>--trace</code> option

The most important troubleshooting feature of CruiseControl.rb is re-starting the builder process with
<code>--trace</code> option, like this:

<pre><code>    > kill [pid of your_project builder process]
    > ./cruise build your_project --trace</code></pre>

This option turns on verbose logging, and makes the builder a lot more talkative. What's even more important, it also
invokes rake with <code>--trace</code> option. It shows you what rake tasks are executed, and prints out the stack trace
when Rake decides to fail the build.

Since most problems with CruiseControl.rb happen within the build (that doesn't fail when it should, or fails when it
shouldn't), this information often makes everything obvious.

h2. "Smart defaults" are not as smart as you are

CruiseControl.rb tries to do the right thing by default. However, there is only so much that it can guess about your 
project, and it may well be a wrong guess. Default behavior should work on trivial Rails applications
with meticulously maintained migration scripts and no custom Rake tasks. If it doesn't work for you, and the reason is
not immediately obvious, forget about the defaults, define <code>cruise</code> task in your project's build and
do the right thing explicitly. It will save your time.

h2. Look at the logs

Dashboard and builders keep their own logs in [cruise]/log directory. If you are not receiving email notifications,
builder crashes on startup, or CruiseControl.rb fails to detect or build new revisions, you can usually find an
explanation for this in the builder log.
