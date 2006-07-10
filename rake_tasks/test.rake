namespace :test do
  desc 'Test CodeRay Demos'
  task :demos do
    system 'ruby -wd ./demo/suite.rb'
  end

  desc 'Test CodeRay'
  task :scanners do
    system 'ruby -w ./test/suite.rb'
  end
end

task :test => 'test:scanners'
task :demos => 'test:demos'