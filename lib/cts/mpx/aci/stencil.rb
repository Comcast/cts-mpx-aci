module Cts
  module Mpx
    module Aci
      # Container for a selection of queries to run on an account.
      # @!attribute [rw] name
      #   @return [String] Name of the stencil
      # @!attribute [rw] original_url
      #   @return [String] If applicable, the original location of the asset.
      # @!attribute [rw] schema
      #   @return [String] Schema of this stencil
      # @!attribute [rw] queries
      #   @return [String] Queries to perform in the collect object
      class Stencil
        include Creatable

        attribute name: 'name', kind_of: String
        attribute name: 'original_url', kind_of: String
        attribute name: 'schema', kind_of: String
        attribute name: 'queries', kind_of: Array

        # find a stencil in the loaded stencils by name.   when used with no parameter will show all available stencils.
        #
        # @param  key [String] name of the stencil
        # @return [Stencil] referenced stencil
        def self.[](key = nil)
          Stencil.class_variable_set(:@@available_stencils, {}) unless Stencil.class_variable_defined? :@@available_stencils
          return @@available_stencils[key] if key

          @@available_stencils
        end

        # Smart load a stencil.  This will attemp to parse it as json, then load it as a url, and finally try to load a file.
        #
        # @param  string [String] string to attempt to smart load.
        # @return [Stencil] loaded stencil
        def self.load(string)
          begin
            data = load_string Stencil.parse_json(string)
          rescue ArgumentError
            return load_url(string) if string.start_with? 'http'

            return load_file string
          end

          load_string(string) if data
        end

        # Attempt to open a local file for reading, loading in the JSON if it is able.
        #
        # @param  file [String] file of the file to load.
        # @raise  [RuntimeError] If file could not be found
        # @raise  [RuntimeError] If file is empty.
        # @return [Stencil] loaded stencil
        def self.load_file(file)
          raise "Could not find file #{file}." unless File.exist? file

          content = File.read(file)
          raise RuntimeError if content.empty?

          stencil = load_string(content)
          stencil.original_url = file
          stencil
        end

        # Attempt to open a local file for reading, loading in the JSON if it is able.
        #
        # @param  string [String] string to be parsed and loaded.
        # @raise  [ArgumentError] if the parsed queries is not an array
        # @return [Stencil] loaded stencil
        def self.load_string(string)
          data = Stencil.parse_json(string)

          stencil = Stencil.new
          stencil.name = data['name']
          raise ArgumentError, "queries is not a kind of Array" unless data['queries'].is_a? Array

          stencil.queries = data['queries']

          @@available_stencils[stencil.name] = stencil
          stencil
        end

        # Attempt to open a local file for reading, loading in the JSON if it is able.
        #
        # @param  url [String] url to be fetched and passed to load_string
        # @raise  [ArgumentError] if the url is not valid
        # @return [Stencil] loaded stencil
        def self.load_url(url)
          begin
            URI.parse url
          rescue URI::InvalidURIError
            raise ArgumentError, "#{url} is not a url"
          end

          load_string(Excon.get(url).body)
        end

        # Attempt to open a local file for reading, loading in the JSON if it is able.
        #
        # @param  string [String] string is parsed and returned as a hash
        # @raise  [ArgumentError] if the arugment is not a type of a string
        # @raise  [ArgumentError] if the string could not be parsed
        # @return [Hash] hash of the data from the json
        def self.parse_json(string)
          raise ArgumentError, "#{string.class} is not a kind of String" unless string&.is_a?(String)

          begin
            data = Oj.load(string)
          rescue Oj::ParseError
            raise ArgumentError, "could not be parsed"
          end

          data
        end

        def initialize
          Stencil.class_variable_set(:@@available_stencils, {}) unless Stencil.class_variable_defined? :@@available_stencils
          @name = ""
          @original_url = ""
          @queries = []
          @schema = 1
        end

        # Attempt to open a local file for reading, loading in the JSON if it is able.
        #
        # @param  account_id [String] account_id account_id to collect from
        # @param  user [String] user to use to make the collection.
        # @raise  [ArgumentError] if the arugment is not a type of a string
        # @raise  [ArgumentError] if no queries are provided
        # @return [Collect] a collect object created from the json and parameters passed in.
        def to_collect(account_id: nil, user: nil)
          raise ArgumentError, 'queries must contain entries' unless queries.any?

          collect = Tasks::Collect.new
          collect.account_id = account_id if account_id
          collect.user = user if user

          queries.each do |q|
            query = Query.create service: q[:service], endpoint: q[:endpoint]
            collect.queries.push query
          end

          collect
        end
      end
    end
  end
end
