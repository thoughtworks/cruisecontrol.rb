@setlocal
@echo on
rm *.zip
rm -rf \tmp\cruise
git clone git://github.com/thoughtworks/cruisecontrol.rb.git /tmp/cruise

pushd .
cd \tmp\cruise
rake package
popd

copy \tmp\cruise\pkg\*.zip .
