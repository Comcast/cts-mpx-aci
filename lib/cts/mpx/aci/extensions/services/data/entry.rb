module Theplatform
  module Services
    module Data
      # extensions to the Theplatform::Services::Data::Entry
      class Entry
        # Collection of dependencies required to deploy this entry
        #
        # @return [Array] unordered list of dependencies
        def dependencies
          dependencies = []
          Cts::Mpx::Aci::Transformations.traverse_for(to_hash['entry'], :transform) do |_k, v|
            next if v.start_with? "http://access.auth.theplatform.com/data/Account"
            next if v == "urn:cts:aci:target-account"
            dependencies.push v
            v
          end
          dependencies.uniq
        end

        # return the difference between two entri

        # true if any reference is found in the entry, false otherwise.
        #
        # @return [Boolean]
        def includes_reference?
          output = false
          Cts::Mpx::Aci::Transformations.traverse_for(to_hash['entry'], :transform) do |_k, v|
            output = true
            v
          end
          output
        end

        # true if any transformed reference is found in the entry, false otherwise.
        #
        # @return [Boolean]
        def includes_transformed_reference?
          ref = false
          Cts::Mpx::Aci::Transformations.traverse_for(to_hash['entry'], :untransform) do |_k, v|
            ref = true
            v
          end
          ref
        end

        # @return [String] computed filename of the entry.
        def filename
          raise 'Entry must include an guid field' unless fields.include? 'guid'
          "#{entry['guid']}.json"
        end

        # @return [String] computed path of the entry.
        def directory
          "#{service}/#{endpoint}"
        end

        # @return [String] complete filepath for an entry
        def filepath
          "#{directory}/#{filename}"
        end

        # @return [String] MD5 hash, based on formatted JSON
        def hash
          Digest::MD5.hexdigest to_s
        end

        # return the difference between two entries
        def diff(other_entry)
          raise ArgumentError, 'an entry must be supplied' unless other_entry.class == self.class
          raise ArgumentError, 'both entries must have the same service' unless service == other_entry.service
          raise ArgumentError, 'both entries must have the same endpoint' unless endpoint == other_entry.endpoint
          Diffy::Diff.new(to_s, other_entry.to_s).to_s
        end

        # transform all references in this entry
        # @raise [RuntimeError] if guid field is not included
        # @raise [RuntimeError] if ownerId field is not included
        # @raise [RuntimeError] if user is not set
        def transform
          raise_entry_exceptions!
          hash = to_hash['entry']
          output = Cts::Mpx::Aci::Transformations.traverse_for(hash, :transform) do |_k, v|
            if Cts::Mpx::Aci::Validators.field_reference? v
              Cts::Mpx::Aci::Transformations.transform_field_reference field_reference: v, user: user
            else
              Cts::Mpx::Aci::Transformations.transform_reference reference: v, user: user, original_account: ownerId
            end
          end
          load_from_hash "$xmlns" => namespace, 'entry' => { "id" => id }.merge(output)
        end

        # untransform all transformed references in this entry
        # @raise [RuntimeError] if guid field is not included
        # @raise [RuntimeError] if ownerId field is not included
        # @raise [RuntimeError] if user is not set
        def untransform(target_account)
          raise_entry_exceptions!
          hash = to_hash['entry']
          output = Cts::Mpx::Aci::Transformations.traverse_for(hash, :untransform) do |_k, v|
            if Cts::Mpx::Aci::Validators.transformed_field_reference? v
              Cts::Mpx::Aci::Transformations.untransform_field_reference transformed_reference: v, user: user
            else
              Cts::Mpx::Aci::Transformations.untransform_reference transformed_reference: v, user: user, target_account: target_account
            end
          end
          load_from_hash "$xmlns" => namespace, 'entry' => { "id" => id }.merge(output)
        end

        def endpoint
          @endpoint.tr '/', ''
        end

        # :nocov:
        # addresses a bug in the SDK.    in the load from hash, the result['entries'].    Adding '.first' is the fix so only an entry is returned, not an array.
        def save_to_service
          if existing_entry?
            service_module.send "put_#{endpoint.split(/(?=[A-Z])/).join('_').downcase}", user, [to_hash(include_read_only: false)["entry"]], namespace: namespace
          else
            result = service_module.send "post_#{endpoint.split(/(?=[A-Z])/).join('_').downcase}", user, [to_hash(include_read_only: false)["entry"]], namespace: namespace
            load_from_hash("entry" => result['entries'].first) if result
          end
          true
        end
        # :nocov:

        private

        def raise_entry_exceptions!
          raise 'Entry must include an guid field' unless fields.include? 'guid'
          raise 'Entry must include an ownerId field' unless fields.include? 'ownerId'
          raise 'Entry must have user set' unless user
        end
      end
    end
  end
end
