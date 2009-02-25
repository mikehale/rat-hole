$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'hoe-patched' # because it supports README.*
require 'rat_hole'

Hoe.new('rat-hole', RatHole::VERSION) do |p|
  p.summary = 'Rack compliant proxy'
  p.description = p.paragraphs_of('README.rdoc', 0...1).to_s
  p.url = 'http://github.com/mikehale/rat-hole'
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['rack', '>= 0.9.1']
  p.extra_dev_deps << ['rr', '>= 0.6.0']
  p.extra_dev_deps << ['hpricot', '>= 0.6.164']
  p.extra_dev_deps << ['newgem', '>= 1.1.0']
  p.extra_dev_deps << ['cucumber', '>= 0.1.12']
  p.author << 'Michael Hale'
  p.author << 'David Bogus'
  p.email = 'mikehale@gmail.com'
end

desc %(Update the gemspec so that github will build a new gem: http://gems.github.com/)
task :update_gemspec do
  begin
    old_stdout = STDOUT.dup
    STDOUT.reopen('rat-hole.gemspec')
    Rake::Task["debug_gem"].invoke
  ensure
    STDOUT.reopen(old_stdout)
  end
end
