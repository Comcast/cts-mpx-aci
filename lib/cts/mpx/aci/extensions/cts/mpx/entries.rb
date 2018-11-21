module Cts
  module Mpx
    # extensions to the Cts::Mpx::Collection
    class Entries
      # All entries in the collections.
      #
      # @return [hash] of entries with filepath as key and md5 hash as value
      def files
        hash = {}
        entries.map { |e| hash.store "#{e.directory}/#{e.filename}", e.hash }
        hash
      end

      # transform every entry
      def transform(user)
        each { |entry| entry.transform user }
        nil
      end

      # untransform every entry
      #
      # @param [String] target_account to transform to
      def untransform(user, target_account)
        each { |entry| entry.untransform(user, target_account) }
        nil
      end
    end
  end
end
