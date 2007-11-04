@setlocal
rem rm -rf /tmp/cruise
rem svn co svn://rubyforge.org/var/svn/cruisecontrolrb/trunk /tmp/cruise

pushd .
cd \tmp\cruise
rake package
popd

cp /tmp/cruise/pkg/*.zip .
