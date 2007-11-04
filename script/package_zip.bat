@setlocal
@echo on
rm *.zip
rm -rf \tmp\cruise
svn co svn://rubyforge.org/var/svn/cruisecontrolrb/trunk /tmp/cruise

pushd .
cd \tmp\cruise
rake package
popd

copy \tmp\cruise\pkg\*.zip .
