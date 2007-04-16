def status_file(dir)
  Dir["#{dir}/build_status.*"].first rescue nil
end

desc "migrate build directories from 1.1 to 1.2"
task :migrate_to_1_2 do
  Dir["projects/*/build-*"].reject{|path| path =~ /build-.*-.*in.*s/}.each do |dir|
    next if status_file(dir).nil?
    status = File.basename(status_file(dir)).sub("build_status.", "")
    dest_dir = dir + "-" + status
    rm status_file(dir)
    mv dir, dest_dir
  end
end