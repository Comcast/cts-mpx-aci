require 'bundler'
require 'bundler/setup'
require 'cgi'
require 'diffy'
require 'logging'
require 'open3'
require 'rubygems'
require 'cts/mpx'

require 'cts/mpx/aci/extensions/cts/mpx/entries.rb'
require 'cts/mpx/aci/extensions/cts/mpx/entry.rb'
require 'cts/mpx/aci/stencil'
require 'cts/mpx/aci/tasks/collect'
require 'cts/mpx/aci/tasks/image'
require 'cts/mpx/aci/tasks/deploy'
require 'cts/mpx/aci/transformations'
require 'cts/mpx/aci/validators'
require 'cts/mpx/aci/version'

# Comcast Technology Solutions
module Cts
  # MPX product
  module Mpx
    # Account Continuous Integration.
    module Aci
      module_function

      @logger = Logging.logger[self]
      @options = {}
      %i[colorize_stdout log_to_file log_to_stdout].each { |o| @options[o] = false }
      Logging.color_scheme('bright', levels:  { info:  :green,
                                                warn:  :yellow,
                                                error: :red,
                                                fatal: %i[white on_red] },
                                     date:    :blue,
                                     logger:  :cyan,
                                     message: :magenta)

      # build a new object from the options provided
      #
      # @return [nil] nil
      def configure_options
        @logger.add_appenders Logging.appenders.file("cts-aci-mpx-#{Time.now.to_i}.log", layout: Logging.layouts.json) if @options[:log_to_file]

        @logger.add_appenders Logging.appenders.stdout level: :info, layout: Logging.layouts.pattern(pattern: '%m\n') if @options[:log_to_stdout] || @options[:colorize_stdout]

        return unless @options[:colorize_stdout]

        layout = Logging.layouts.pattern(pattern:      '[%d] %-5l %c: %m\n',
                                         color_scheme: 'bright')
        @logger.appenders.last.layout = layout
        nil
      end

      # the logger
      #
      # @return [Logging::Logger]
      def logger
        @logger
      end

      # options method
      #
      # @param  key [String] (optional) option to look up
      # @param  value [*] Value to assign to the option array
      # @return [*] value of the option returned
      # @return [Hash] entire option hash (with no parameter)
      def options(key = nil, value = nil)
        return @options unless key
        return @options[key] unless value

        @options[key] = value
      end
    end
  end
end
