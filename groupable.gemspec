require_relative "lib/groupable/version"

Gem::Specification.new do |spec|
  spec.name        = "groupable"
  spec.version     = Groupable::VERSION
  spec.authors     = [ "Yugo TERADA" ]
  spec.email       = [ "yugo@ensemble-lab.com" ]
  spec.homepage    = "https://github.com/aspick/backstage"
  spec.summary     = "A Rails Engine for group and membership management."
  spec.description = "Groupable is a Rails Engine that provides flexible group and membership management with role-based permissions and invite functionality."

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aspick/backstage"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.2.2.2"
end
