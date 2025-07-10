

Gem::Specification.new do |spec|
  spec.name          = "simple_game_server"
  spec.version       = "0.1.0"
  spec.authors       = ["Nick Hart"]
  spec.email         = ["nickhart@gmail.com"]

  spec.summary       = "Shared client library for Simple Game Server examples."
  spec.description   = "This library contains reusable API clients, services, and utilities for connecting to the Simple Game Server API."
  spec.homepage      = "https://github.com/nickhart/simple-game-server"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "action_cable_client", ">= 0.1"
end