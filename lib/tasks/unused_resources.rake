desc "find and list unused resources"
task ['doc:unused_resouces'] do
  resources = Dir["#{Rails.root}/public/images/**/*.*"].collect {|f| File.basename(f)}
  docs = Dir["#{Rails.root}/app/views/**/*.*"] + Dir["#{Rails.root}/public/stylesheets/**/*.css"]

  resources.each do |resource|
    used = docs.any? do |doc|
      File.read(doc) =~ /#{resource}/
    end

    p resource unless used
  end
  
end
