module Cts
  module Mpx
    module Aci
      # Wireline Validators
      module Validators
        module_function

        # Test if a string is a reference or not
        # @param [String] uri to test if it is a reference or not
        # @return [Boolean]
        def reference?(uri)
          Cts::Mpx::Validators.reference?(uri)
        end

        def field_reference?(uri)
          begin
            ref = URI.parse uri
          rescue URI::InvalidURIError
            return false
          end

          return false if ref.host == 'web.theplatform.com'
          return false unless ref.scheme == "http" || ref.scheme == "https"
          return false unless ref.host.end_with? ".theplatform.com"
          return false unless ref.path =~ /Field\/\d+/
          return false if ref.path =~ /\/\D+$/

          true
        end

        # Test if a string is a transformed_reference or not
        # @param [String] string to check if it is a transformed_reference
        # @return [Boolean]
        def transformed_reference?(string)
          return true if [
            'urn:cts:aci:target-account',
            'urn:cts:aci:no-id-found',
            'urn:cts:aci:no-guid-found',
            'urn:cts:aci:no-custom-field-found'
          ].include? string

          urn_regex = /^(?i:urn:(?!urn:)([cC][tT][sS]):(?<nss>(?:[a-z0-9()\/+,-.:=@;$_!*']|%[0-9a-f]{2})+))$/

          return false unless urn_regex =~ string

          nss = urn_regex.match(string)["nss"]
          segments = nss.split(":")

          return false unless /^([aA][cC][iI])$/ =~ segments[0]

          begin
            service = Services[URI.decode_www_form_component(segments[1])]
          rescue RuntimeError
            return false
          end

          return false unless service.endpoints.include? segments[2].gsub('Field', '/Field')
          return false unless /\A\d+\z/ =~ segments[3]

          true
        end

        # Test if a string is a transformed_field_reference or not
        # @param [String] string to check if it is a transformed_field_reference
        # @return [Boolean]
        def transformed_field_reference?(string)
          return false unless transformed_reference? string
          return false unless /Field:\d*:.*$/.match? string

          true
        end

        # test if a directory is an image_directory
        # @param [String] image_directory to check if it is a transformed_reference
        # @return [Boolean]
        def image_directory?(image_directory)
          return false unless File.exist? "#{image_directory}/info.json"

          true
        end

        # test if a image will depoly
        # @param [Tasks::Image] image to check if it is a transformed_reference
        # @return [Boolean]
        def image_deployable?(image)
          return false if image.state == :transformed || image.state == 'transformed'
          return false if image.entries.collection.empty?

          image.entries.each do |entry|
            Transformations.traverse_for(entry.to_h, :untransform) do |_k, v|
              return false if v =~ /^urn:cts:aci:no-(gu)?id-found$/
            end
          end
          true
        end

        # Test if a string is a transformed_reference or not
        # @param [String] filename to check if it is a valid info.json or not
        # @return [Boolean]
        def info_file?(filename)
          raise "could not find an info.json" unless File.exist? filename

          begin
            Oj.load(File.read(filename))
          rescue Oj::ParseError
            return false
          end

          true
        end
      end
    end
  end
end
