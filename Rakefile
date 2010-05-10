require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ruport_report_builder"
    gem.summary = %Q{Simple wrapper for common ruport tasks}
    gem.description = %Q{Simple wrapper for common ruport tasks}
    gem.email = "code@milemeter.com"
    gem.homepage = "http://github.com/milemeter/ruport_report_builder"
    gem.authors = ["Doug Bryant", "John Riney"]
    gem.add_dependency('ruport', '>= 1.4.0')
    gem.add_dependency('activerecord', '>= 2.0.0')
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency 'sqlite3-ruby' 
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Ruport Report Builder #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
