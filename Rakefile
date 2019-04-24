require 'bundler/gem_tasks'
require 'rubocop/rake_task'

$LOAD_PATH.unshift File.dirname(__FILE__) unless $LOAD_PATH.include? '.'

ROOT = '.'.freeze
LIB_ROOT = File.join ROOT, 'lib'

RuboCop::RakeTask.new

task :default => %i[test rubocop]

if File.directory? 'rake_tasks'

  # load rake tasks from subfolder
  Dir['rake_tasks/*.rake'].sort.each do |task_file|
    load task_file
  end

else

  # fallback tasks when rake_tasks folder is not present (eg. in the distribution package)
  desc 'Run CodeRay tests (basic)'
  task :test do
    ruby './test/functional/suite.rb'
    ruby './test/functional/for_redcloth.rb'
  end

  gem 'rdoc' if defined? gem
  require 'rdoc/task'
  desc 'Generate documentation for CodeRay'
  Rake::RDocTask.new :doc do |rd|
    rd.title = 'CodeRay Documentation'
    rd.main = 'README_INDEX.rdoc'
    rd.rdoc_files.add Dir['lib']
    rd.rdoc_files.add rd.main
    rd.rdoc_dir = 'doc'
  end

end
