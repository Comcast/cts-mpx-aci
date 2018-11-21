module Cts
  module Mpx
    module Aci
      # contains the logic to transform/untransform an entry.
      module Transformations
        module_function

        # Transform a reference into a transformed_reference
        # @param [User] user that will make the service calls.
        # @param [String] original_account to do the transformation from
        # @param [String] reference to transform to a transformed reference
        # @return [String] transformed_reference
        def transform_reference(reference: nil, user: nil, original_account: nil)
          return "urn:cts:aci:target-account" if reference == original_account
          return reference unless Validators.reference? reference

          service_info = Services.from_url reference
          endpoint = service_info[:endpoint]
          service = service_info[:service]
          return reference if service.start_with? "User Data Service"

          response = Services::Data.get user: user, service: service, endpoint: endpoint, ids: reference.split('/').last

          return "urn:cts:aci:no-id-found" unless (entry = response.data["entries"].first)

          return "urn:cts:aci:no-guid-found" unless (guid = entry["guid"])

          "urn:cts:aci:#{URI.encode_www_form_component(service)}:#{endpoint}:#{entry['ownerId'].split('/').last}:#{guid}"
        end

        # Transform a field reference into a transformed_field_reference
        # @param [User] user that will make the service calls.
        # @param [String] field_reference to transform to a transformed field reference
        # @return [String] transformed_field_reference
        def transform_field_reference(field_reference: nil, user: nil)
          return field_reference unless Validators.field_reference? field_reference

          service_info = Services.from_url field_reference
          endpoint = service_info[:endpoint]
          service = service_info[:service]
          response = Services::Data.get user: user, service: service, endpoint: endpoint, ids: field_reference.split('/').last, fields: 'ownerId,fieldName,namespace'
          return "urn:cts:aci:no-id-found" unless (entry = response.data["entries"].first)
          return "urn:cts:aci:no-qualified-field-name-found" unless entry["fieldName"]

          namespace = response.data['namespace']
          owner_id = entry['ownerId'].split('/').last
          "urn:cts:aci:#{URI.encode_www_form_component(service)}:#{endpoint}:#{owner_id}:#{namespace}$#{entry['fieldName']}"
        end

        # Untransform a transformed_reference into a reference
        # @param [User] user that will make the service calls.
        # @param [String] target_account to do the transformation from
        # @param [String] transformed_reference to transform to a reference
        # @return [String] reference
        def untransform_reference(transformed_reference: nil, user: nil, target_account: nil)
          return target_account if transformed_reference == "urn:cts:aci:target-account"
          return transformed_reference unless Validators.transformed_reference? transformed_reference

          parts = transformed_reference.split ':'
          endpoint = parts[4]
          service = parts[3]
          guid = URI.decode_www_form_component(parts[6])
          owner_id = "http://access.auth.theplatform.com/data/Account/#{parts[5]}"

          response = Services::Data.get user:     user,
                                        service:  service,
                                        endpoint: endpoint,
                                        ids:      transformed_reference.split('/').last,
                                        query:    { byGuid: guid, ownerId: owner_id }

          raise "could not find an entry by guid" unless (entry = response.data["entries"].first)
          raise "service returned too many entries on guid" if response.data["entries"].count > 1

          entry['id']
        end

        # Untransform a transformed_field_reference into a field reference
        # @param [User] user that will make the service calls.
        # @param [String] transformed_field_reference to transform to a reference
        # @return [String] field_reference
        def untransform_field_reference(transformed_field_reference: nil, user: nil, target_account: nil)
          return transformed_field_reference unless Validators.transformed_field_reference? transformed_field_reference

          parts = transformed_field_reference.split ':'
          endpoint = parts[4]
          service = parts[3]
          qualified_field_name = URI.decode_www_form_component(parts[6])
          owner_id = "http://access.auth.theplatform.com/data/Account/#{parts[5]}"

          response = Services::Data.get user:     user,
                                        service:  service,
                                        endpoint: endpoint,
                                        query:    { byQualifiedFieldName: qualified_field_name, ownerId: owner_id }

          raise "could not find an entry by qualified field name" unless (entry = response.data["entries"].first)
          raise "service returned too many entries on qualified field name" if response.data["entries"].count > 1

          entry['id']
        end

        def traverse_for(hash, direction, &block)
          id = hash['id']
          output = hash.reject { |k, _v| k == 'id' }
          output = Transformations.send :traverse_hash, Oj.load(Oj.dump(output)), direction, &block
          { "id" => id }.merge(output)
        end

        # private module method, not explicitly covered
        def traverse_hash(entry, direction, &block)
          entry.each do |field, value|
            case value
            when String
              entry[field] = block.yield field, value if direction == :transform &&
                                                         Validators.reference?(value)
              entry[field] = block.yield field, value if direction == :untransform &&
                                                         Validators.transformed_reference?(value)
            when Array
              entry[field] = traverse_array field, value, direction, &block
            when Hash
              entry[field] = traverse_hash value, direction, &block
            end
          end
        end

        # private module method, not explicitly covered
        def traverse_array(field, value, direction, &block)
          if value.map(&:class).uniq.first == String
            value.map do |v|
              if Validators.reference?(v) || Validators.transformed_reference?(v)
                block.yield field, v
              else
                v
              end
            end
          elsif value.map(&:class).uniq.first == Hash
            value.map { |v| traverse_hash v, direction, &block }
          else
            value
          end
        end
      end
    end
  end
end
