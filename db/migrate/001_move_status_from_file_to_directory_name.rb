require 'fileutils'
include FileUtils

Dir["projects/*/build-*"].reject{|path| path =~ /build-.*-.*in.*s/}.each do |dir|
  status_file = Dir["#{dir}/build_status.*"].first
  next unless status_file
  status_info = File.basename(status_file).sub('build_status.', '')

  new_dirname = "#{dir}-#{status_info}"
  time_stamp = File.mtime(dir)

  rm status_file
  mv dir, new_dirname

  File.utime(time_stamp, time_stamp, new_dirname)
end
