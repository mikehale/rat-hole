require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "rat-hole"
    s.summary = 'Rack compliant http proxy'
    s.email = "mikehale@gmail.com"
    s.homepage = "http://github.com/mikehale/rat-hole"
    s.description = "Rat Hole is a handy library for creating a rack compliant http proxy that allows you to modify the request from the user and the response from the server."
    s.authors = ["Michael Hale", "David Bogus"]
    s.add_dependency('rack', '>= 0.9.1')
    s.has_rdoc = false
    # s.extra_dev_deps << ['rr', '>= 0.6.0']
    # s.extra_dev_deps << ['hpricot', '>= 0.6.164']
    # s.extra_dev_deps << ['newgem', '>= 1.1.0']
    # s.extra_dev_deps << ['cucumber', '>= 0.1.12']
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'rat-hole'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end
rescue LoadError
  puts "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
end

task :default => :test
