Gem::Specification.new do |s|
  s.name     = "rat-hole"
  s.version  = "0.1.0"
  s.date     = "2008-12-17"
  s.summary  = "Rack compliant proxy"
  s.email    = "mikehale@gmail.com"
  s.homepage = "http://github.com/mikehale/rat-hole"
  s.description = "Rat Hole is a handy library for creating a rack compliant http proxy that allows you to modify the request from the user and the response from the server."
  s.has_rdoc = true
  s.authors  = ["Michael Hale", "David Bogus"]
  s.files    = ["History.txt", 
    "README.rdoc", 
    "rat-hole.gemspec", 
    "lib/rat_hole.rb", 
    "lib/util.rb"]
  s.test_files = ["test/test_rat_hole.rb",
    "test/mock_request.rb"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.add_dependency("rack", ["> 0.4.0"])
  s.add_dependency("rr", ["> 0.6.0"])
end
