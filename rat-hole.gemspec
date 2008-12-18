Gem::Specification.new do |s|
  s.name = %q{rathole}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Bogus"]
  s.date = %q{2008-12-17}
  s.description = %q{Rat Hole is a handy class for creating a rack compliant http proxy that allows you to modify the request from the user and the response from the server.  The name is inspired by why's mousehole[http://code.whytheluckystiff.net/mouseHole/]}
  s.email = %q{mikehale@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "Rakefile", "README.rdoc", "rat-hole.gemspec", "lib/rat_hole.rb", "lib/util.rb", "test/test_rat_hole.rb", "test/mock_request.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mikehale/rat-hole}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rathole}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Rack compliant proxy}
  s.test_files = ["test/test_rat_hole.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<rack>, [">= 0.4.0"])
      s.add_development_dependency(%q<rr>, [">= 0.6.0"])
      s.add_development_dependency(%q<hpricot>, [">= 0.6.164"])
      s.add_development_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_development_dependency(%q<cucumber>, [">= 0.1.12"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<rack>, [">= 0.4.0"])
      s.add_dependency(%q<rr>, [">= 0.6.0"])
      s.add_dependency(%q<hpricot>, [">= 0.6.164"])
      s.add_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_dependency(%q<cucumber>, [">= 0.1.12"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0.4.0"])
    s.add_dependency(%q<rr>, [">= 0.6.0"])
    s.add_dependency(%q<hpricot>, [">= 0.6.164"])
    s.add_dependency(%q<newgem>, [">= 1.1.0"])
    s.add_dependency(%q<cucumber>, [">= 0.1.12"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
