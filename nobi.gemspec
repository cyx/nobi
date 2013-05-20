# encoding: utf-8

Gem::Specification.new do |s|
  s.name = "nobi"
  s.version = "0.0.1"
  s.summary = "Ruby port of itsdangerous python signer."
  s.description = "Ruby port of itsdangerous python signer."
  s.authors = ["Cyril David"]
  s.email = ["cyx@cyx.is"]
  s.homepage = "http://cyx.is"
  s.files = Dir[
    "LICENSE",
    "README*",
    "makefile",
    "lib/**/*.rb",
    "*.gemspec",
    "tests/*.*",
  ]

  s.license = "MIT"

  s.add_development_dependency "cutest"
end
