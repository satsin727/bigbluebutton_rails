require 'rubygems'
require 'bundler/setup'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'cucumber'
require 'cucumber/rake/task'

desc 'Default: run specs and features.'
task :default => [:spec, :cucumber]

RSpec::Core::RakeTask.new(:spec)

desc 'Generate documentation.'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BigBlueButton on Rails'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('app/**/*.rb')
end

eval("$specification = begin; #{ IO.read('bigbluebutton_rails.gemspec')}; end")
Gem::PackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc 'Setup RailsApp used in tests.'
namespace "setup" do
  task :rails_app do |app|
    cd "spec/rails_app/"
    # base
    sh "rails destroy bigbluebutton_rails:install"
    sh "rails generate bigbluebutton_rails:install"
    sh "rake db:drop:all"
    sh "rake db:create:all"
    # test
    sh "rake db:migrate RAILS_ENV=test"
    sh "rake db:test:prepare RAILS_ENV=test"
    # development
    sh "rake db:migrate RAILS_ENV=development"
    sh "rake db:seed RAILS_ENV=development"
  end
end

task :cucumber do
  if File.exists? "features/"
    puts "* Gem features"
    sh %{ cucumber features/ }
  end
  puts "* Dummy app features"
  sh %{ cd spec/rails_app; cucumber features/ }
end
