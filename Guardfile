clearing :on

watch 'Guardfile'

guard :bundler do
  watch 'Gemfile'
end

guard 'yard' do
  watch(%r{app/.+\.rb})
  watch(%r{lib/.+\.rb})
  watch(%r{ext/.+\.c})
end

guard :rubocop, cli: ['--format', 'simple', '--require', 'rubocop-rspec'] do
  watch(/lib\/.+\.rb$/)
  watch(/spec\/.+\.rb$/)
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end

guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # Feel free to open issues for suggestions and improvements

  # RSpec files
  rspec = dsl.rspec

  watch("spec/spec_helper_create.rb") { rspec.spec_dir }
  watch("spec/spec_helper_parameters.rb") { rspec.spec_dir }

  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
end
