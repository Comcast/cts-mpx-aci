source 'https://rubygems.org'

# Specify your gem's dependencies in theplatform-aci.gemspec
gemspec

group :development do
  gem 'bump'
  gem "bundler", "~> 1.16"
  gem "rake", "~> 10.0"
  gem "rspec", "~> 3.0"
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'simplecov-console'
end

group :development, optional: true do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-yard'
  gem 'pry'
end

group :documentation, optional: true do
  gem "kramdown"
  gem "nanoc"
  gem "yard"
end
