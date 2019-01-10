lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cts/mpx/aci/version'

Gem::Specification.new do |spec|
  spec.name          = "cts-mpx-aci"
  spec.version       = Cts::Mpx::Aci::VERSION
  spec.authors       = ["Ernie Brodeur"]
  spec.email         = ["ernie.brodeur@cable.comcast.com"]
  spec.summary       = "mpx account continuous integration driver."
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_runtime_dependency "creatable"
  spec.add_runtime_dependency "cts-mpx", "~> 1.1"
  spec.add_runtime_dependency "diffy"
  spec.add_runtime_dependency 'logging'
  spec.add_runtime_dependency "oj"
end
