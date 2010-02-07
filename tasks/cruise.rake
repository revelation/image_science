desc 'Continuous build target'
task :cruise do
  if out = ENV['CC_BUILD_ARTIFACTS']
    mkdir_p out unless File.directory?(out)
  end
  
  Rake::Task["compile"].invoke
  Rake::Task["spec:rcov"].invoke
  mv 'coverage', "#{out}/all test coverage" if out
end
