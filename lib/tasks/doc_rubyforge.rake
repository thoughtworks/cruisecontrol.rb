namespace :doc do
  task :rubyforge do
    gem 'webgen'
    
    images_dir = 'doc/rubyforge_site/src/images'
    
    mkdir images_dir if !File.directory? images_dir
    cp Dir.glob('public/images/*'), images_dir
    
    puts `webgen -d doc/rubyforge_site`
  end
end