# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rat-hole}
  s.version = "0.1.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Hale", "David Bogus"]
  s.date = %q{2009-02-26}
  s.description = %q{Rat Hole is a handy library for creating a rack compliant http proxy that allows you to modify the request from the user and the response from the server.}
  s.email = %q{mikehale@gmail.com}
  s.files = ["CHANGELOG.rdoc", "Manifest.txt", "README.rdoc", "VERSION.yml", "lib/rat_hole.rb", "lib/rat_hole_test.rb", "lib/util.rb", "test/mock_request.rb", "test/test_rat_hole.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mikehale/rat-hole}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Rack compliant http proxy}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0.9.1"])
    else
      s.add_dependency(%q<rack>, [">= 0.9.1"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0.9.1"])
  end
end
