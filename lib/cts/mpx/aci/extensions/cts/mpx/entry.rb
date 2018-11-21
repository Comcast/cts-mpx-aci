module Cts
  module Mpx
    # extensions to the Cts::Mpx::Entry
    class Entry
      # Collection of dependencies required to deploy this entry
      #
      # @return [Array] unordered list of dependencies
      def dependencies
        dependencies = []
        Cts::Mpx::Aci::Transformations.traverse_for(to_h[:entry], :transform) do |_k, v|
          next if v.start_with? "http://access.auth.theplatform.com/data/Account"
          next if v == "urn:cts:aci:target-account"

          dependencies.push v
        end
        dependencies.uniq
      end

      # return the difference between two entries
      def diff(other_entry)
        raise ArgumentError, 'an entry must be supplied' unless other_entry.class == self.class
        raise ArgumentError, 'both entries must have the same service' unless service == other_entry.service
        raise ArgumentError, 'both entries must have the same endpoint' unless endpoint == other_entry.endpoint

        Diffy::Diff.new(to_s, other_entry.to_s).to_s
      end

      # @return [String] computed filename of the entry.
      def filename
        raise 'Entry must include a guid field' unless fields.collection.map(&:name).include? 'guid'

        "#{fields['guid']}.json"
      end

      # @return [String] computed path of the entry.
      def directory
        "#{service}/#{endpoint}"
      end

      def exists_by?(user, query)
        raise ArgumentError, "user must be signed in" unless user&.token
        raise ArgumentError, "query must be a type of Query" unless query.is_a? Query

        query.run(user: user)
        return true if query.page.entries&.count&.positive?

        false
      end

      # @return [String] complete filepath for an entry
      def filepath
        "#{directory}/#{filename}"
      end

      # @return [String] MD5 hash, based on formatted JSON
      def hash
        Digest::MD5.hexdigest to_s
      end

      # true if any reference is found in the entry, false otherwise.
      #
      # @return [Boolean]
      def includes_reference?
        included = false
        Cts::Mpx::Aci::Transformations.traverse_for(to_h[:entry], :transform) do |_k, v|
          included = true
          v
        end
        included
      end

      # true if any transformed reference is found in the entry, false otherwise.
      #
      # @return [Boolean]
      def includes_transformed_reference?
        ref = false

        Cts::Mpx::Aci::Transformations.traverse_for(to_h[:entry], :untransform) do |_k, v|
          ref = true
          v
        end
        ref
      end

      # transform all references in this entry
      # @raise [RuntimeError] if guid field is not included
      # @raise [RuntimeError] if ownerId field is not included
      # @raise [RuntimeError] if user is not set
      def transform(user)
        raise_entry_exceptions!(user)
        hash = to_h[:entry]
        output = Cts::Mpx::Aci::Transformations.traverse_for(hash, :transform) do |_k, v|
          if Cts::Mpx::Aci::Validators.field_reference? v
            Cts::Mpx::Aci::Transformations.transform_field_reference field_reference: v, user: user
          else
            Cts::Mpx::Aci::Transformations.transform_reference reference: v, user: user, original_account: fields['ownerId']
          end
        end
        @fields = Fields.create_from_data(data: output, xmlns: to_h[:namespace])
        self
      end

      # untransform all transformed references in this entry
      # @raise [RuntimeError] if guid field is not included
      # @raise [RuntimeError] if ownerId field is not included
      # @raise [RuntimeError] if user is not set
      def untransform(user, target_account)
        raise_entry_exceptions!(user)
        hash = to_h[:entry]
        output = Cts::Mpx::Aci::Transformations.traverse_for(hash, :untransform) do |_k, v|
          if Cts::Mpx::Aci::Validators.transformed_field_reference? v
            Cts::Mpx::Aci::Transformations.untransform_field_reference transformed_reference: v, user: user
          else
            Cts::Mpx::Aci::Transformations.untransform_reference transformed_reference: v, user: user, target_account: target_account
          end
        end
        @fields = Fields.create_from_data(data: output, xmlns: to_h[:namespace])
        self
      end

      private

      def raise_entry_exceptions!(user)
        raise 'Entry must include an guid field' unless fields.to_h.key?('guid')
        raise 'Entry must include an ownerId field' unless fields.to_h.key?('ownerId')
        raise 'Entry must have user set' unless user
      end
    end
  end
end
