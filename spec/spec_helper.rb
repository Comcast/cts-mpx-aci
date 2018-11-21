$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
# load first
require 'simplecov'
require 'simplecov-console'
require 'pry'
require 'cts/mpx'
require_relative 'helper/collection'
require_relative 'helper/create'
require_relative 'helper/entry'
require_relative 'helper/image'
require_relative 'helper/parameters'

include Cts::Mpx::Spec

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "tmp/examples.txt"
end

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter
]

SimpleCov.start do
  add_filter "/spec/"
end

require 'cts/mpx/aci'
Excon.defaults[:mock] = true
