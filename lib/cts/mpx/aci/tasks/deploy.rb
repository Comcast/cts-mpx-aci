module Cts
  module Mpx
    module Aci
      module Tasks
        # Responsible for deploying an image to an account.
        # @!attribute [rw] user
        #   @return [User] user to make data service calls with
        # @!attribute [rw] account
        #   @return [String] relative account or nil when untransformed
        # @!attribute [rw] image
        #   @return [Cts::Mpx::Aci::Tasks::Image]Image containing entries to deploy
        class Deploy
          include Creatable

          attribute name: 'account', kind_of: String
          attribute name: 'image', kind_of: Tasks::Image
          attribute name: 'user', kind_of: User
          attribute name: 'pre_block', kind_of: Proc
          attribute name: 'post_block', kind_of: Proc

          # Any dependencies the image may contain
          # @return [Hash] dependency hash keyed by entry
          def dependencies
            hash = {}
            image.entries.each do |e|
              deps = e.dependencies
              hash.store e.id, deps if deps.any?
            end
            hash
          end

          # rubocop:disable Metrics/AbcSize
          # reason: these classes is as thin as it can get.  not splitting it up to satisify rubocop.
          # deploy a transformed image to an account
          # @param [String] target_account to deploy to
          # @raise [RuntimeError] when image is not deployable
          def deploy(target_account, *args)
            raise "not a deployable image" unless Validators.image_deployable? image
            raise "not a deployable image" unless deploy_order

            deploy_order.each do |ref|
              entry = image.entries.find { |e| e.id == ref }
              entry = block_update_entry entry, *args, &pre_block if pre_block

              query = Query.create service: entry.service, endpoint: entry.endpoint, fields: 'id,guid'
              query.query['byOwnerId'] = target_account

              if entry.id.include? 'Field/'
                query.query['byQualifiedFieldName'] = "#{entry.fields['namespace']}$#{entry.fields['fieldName']}"
              else
                query.query['byGuid'] = entry.fields['guid']
              end

              if entry.exists_by? user, query
                method = 'PUT'
                response = query.run(user: user)
                entry.id = response.page.entries.first["id"]
              else
                entry.id = nil
                entry.service = query.service
                entry.endpoint = query.endpoint
                method = 'POST'
              end

              entry.fields['ownerId'] = target_account
              entry.save user: user
              block_update_entry entry, *args, &post_block if post_block

              logger.info "deployed #{entry.fields['guid']} to #{target_account} as #{entry.id || 'new_id'} with #{user.username} via a #{method} call"
            end

            true
          end

          # @return [Array] order to deploy objects in
          # @return [nil] if image state is transformed.
          # @return [nil] if a deploy order could not be generated.
          def deploy_order
            return nil unless image.state == :untransformed

            hash = dependencies
            list = image.entries.map(&:id) - dependencies.keys

            100.times do |_i|
              break unless hash.any?

              hash.delete_if { |k, _v| list.include? k }

              new_hash = hash.select { |_k, v| (v - list).empty? }
              list += new_hash.keys if new_hash.any?
            end

            return list.uniq if image.entries.map(&:id).count == list.count

            nil
          end
          # rubocop:enable Metrics/AbcSize

          def block_update_entry(entry, *args, &block)
            raise ArgumentError, 'block must be provided' unless block
            raise ArgumentError, 'argument must be an entry' unless entry.is_a? Entry

            e = entry.dup
            block.yield e, args
            e
          end

          private

          def logger
            Aci.logger
          end
        end
      end
    end
  end
end
