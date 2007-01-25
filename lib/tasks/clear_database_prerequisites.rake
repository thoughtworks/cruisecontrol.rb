[:'test:recent', :'test:units', :'test:functionals', :'test:integration'].each do |task|
  # Removes each of their db:test:prepare dependency
  Rake::Task[task].prerequisites.clear
end