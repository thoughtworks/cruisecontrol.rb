h1. Troubleshooting

p(hint). This section needs users contributions more than any other. Authors know very well how everything works, and
what the assumptions/limitations are. When something goes wrong, we simply dive into the source code.
Oddly enough, it means that we don't have much troubleshooting experience! At least, not of the kind that can be useful
to a casual reader.


h2. <code>--trace</code> option

The most important troubleshooting feature of CruiseControl.rb is re-starting it with <code>--trace</code> option, like this:

<pre><code>    > kill [pid of dashboard or builder process]
    > ./cruise build your_project --trace</code>
       ... or even ...
    > ./cruise start your_project --trace</code></pre>

This option turns on verbose logging, and makes CC.rb builders a lot more talkative. What's even more important, it also
invokes Rake with <code>--trace</code> option, too, so that the build.log will have some more details, including complete 
stack trace to the point where Rake decided to fail the build.

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
builder crashes on startup, or CruiseControl.rb fails to detect or build new revisions, an explanation can usually be found
in the builder log.

