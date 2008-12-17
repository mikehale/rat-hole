# -*- ruby -*-

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'hoe'
require 'rat_hole.rb'

Hoe.new('rathole', RatHole::VERSION) do |p|
  p.summary = 'Rack compliant proxy'
  p.description = p.paragraphs_of('README.rdoc', 0..1).join("\n\n")
  p.url = 'http://github.com/mikehale/rat-hole'
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['rack', '>= 0.4.0']
  p.extra_deps << ['rr', '>= 0.6.0']
  p.developer('Michael Hale', 'mikehale@gmail.com')
  
end

# vim: syntax=Ruby
