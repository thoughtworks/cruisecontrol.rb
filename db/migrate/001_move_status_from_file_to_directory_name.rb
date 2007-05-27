require 'fileutils'
include FileUtils

Dir["projects/*/build-*"].reject{|path| path =~ /build-.*-.*in.*s/}.each do |dir|
  status_file = Dir["#{dir}/build_status.*"].first
  next unless status_file
  status_info = File.basename(status_file).sub('build_status.', '')
  rm status_file
  mv dir, "#{dir}_#{status_info}"
end
