module Cts
  module Mpx
    module Aci
      module Tasks
        # Collect class for gathering data from MPX.
        class Collect
          include Creatable

          attribute name: 'account_id', kind_of: String
          attribute name: 'user',       kind_of: User
          attribute name: 'queries',    kind_of: Array
          attribute name: 'entries',    kind_of: Entries

          # Executes the array of queries one by one.   Collecting the result into the collections attribute.
          # @raise [RuntimeError] when queries is not set correctly
          # @raise [ArgumentError] when the user attribute is not set
          # @raise [ArgumentError] when the account_id attribute is not set
          # @raise [ArgumentError] when a query does not have service set
          # @raise [ArgumentError] when a query does not have endpoint set
          def collect
            raise "empty queries array" if @queries&.empty?
            raise 'must set the queries attribute.' unless queries

            @entries = Entries.new

            queries.each do |config|
              query = run_query(config)

              if query&.entries.count.positive?
                log_collected_zero_entries config
                next
              end

              @entries += query.page.to_mpx_entries
              @entries.each do |entry|
                # if we collect the read only fields, it just messes everything up.
                # best to just not collect them.
                service_read_only_fields.each { |field| entry.fields.remove field }

                log_collected entry
              end
            end
          end

          def initialize
            @account_id = ""
            @user = nil
            @entries = Entries.new
            @queries = []
          end

          def queries=(new_queries)
            raise ArgumentError unless new_queries.is_a? Array
            raise ArgumentError if new_queries.map { |e| e.is_a? Hash }.include? false

            @queries = new_queries
          end

          private

          def service_read_only_fields
            ["updated", "added", "addedByUserId", "updatedByUserId", "version"]
          end

          def logger
            Aci.logger
          end

          def log_collected(entry)
            logger.info "collected: id: #{entry.fields['id']} guid: #{entry.fields['guid']}"
          end

          def log_collected_zero_entries(config)
            logger.info "collected zero results for #{config['service']}/#{config['endpoint']}"
          end

          def run_query(config)
            raise ArgumentError, 'must set the user attribute.' unless user
            raise ArgumentError, 'must set the account_id attribute.' unless account_id

            raise ArgumentError, "#{config} does not have service set" if config["service"].empty?
            raise ArgumentError, "#{config} does not have endpoint set" if config["endpoint"].empty?

            query = Query.create config
            query.run user: user
          end
        end
      end
    end
  end
end
