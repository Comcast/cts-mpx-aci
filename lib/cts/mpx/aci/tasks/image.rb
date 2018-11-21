module Cts
  module Mpx
    module Aci
      module Tasks
        # Image class for gathering a set of service data as a single collection.
        #
        # @!attribute [rw] entries
        #   @return [Hash] set of entries to generate the image from
        # @!attribute [rw] schema
        #   @return [String] schema of the image
        # @!attribute [rw] user
        #   @return [User] user to make data service calls with
        # @!attribute [r] account_id
        #   @return [String] relative account_id or nil when untransformed
        # @!attribute [r] date_taken
        #   @return [DateTime] Date the image was instantiated
        # @!attribute [r] state
        #   @return [String] :transformed or :untransformed
        class Image
          include Creatable

          attribute  name: 'entries', kind_of: Entries
          attribute  name: 'schema', kind_of: Integer
          attribute  name: 'user', kind_of: User
          attribute  name: 'account_id', kind_of: String
          attribute  name: 'date_taken', kind_of: Time
          attribute  name: 'state', kind_of: String

          # load an image from directory
          #
          # @param  user [String] user to set the image and entries to
          # @return [Cts::Mpx::aciTasks::Image] image with entries loaded and info set.
          def self.load_from_directory(directory, user = nil)
            i = new
            i.load_from_directory directory, user
            i
          end

          # All entries in the entries, including the md5 hash of the data.
          #
          # @return [Hash] filepath is key, value is md5
          def files
            entries.map(&:filepath)
          end

          # Generate information report for the image.
          #
          # @return [Hash] contains the information about the image.
          def info
            {
              account_id: @account_id,
              date_taken: @date_taken.iso8601,
              username:   @user.nil? ? "" : @user.username,
              schema:     @schema,
              state:      @state,
              files:      files
            }
          end

          def initialize
            @account_id = ""
            @entries = Entries.new
            @date_taken = Time.now
            @files = {}
            @state = :untransformed
            @schema = 1
            @user = nil
          end

          # save an image to a directory
          #
          # @param directory [String] the name of the directory to save to
          def save_to_directory(directory)
            entries.each do |entry|
              FileUtils.mkdir_p "#{directory}/#{entry.directory}"
              File.write "#{directory}/#{entry.filepath}", entry.to_s
            end

            File.write "#{directory}/info.json", Oj.dump(info, indent: 2)
            true
          end

          # load an image from directory
          #
          # @param  user [String] user to set the image and entries to
          # @return [Cts::Mpx::Aci::Tasks::Image] image with entries loaded and info set.
          def load_from_directory(directory, user = nil)
            raise "#{directory} does not contain a valid image." unless Validators.image_directory? directory

            info = load_json_or_error "#{directory}/info.json"

            ["date_taken", "account_id", "schema", "username", "state"].each do |param|
              instance_variable_set "@#{param}", info[param]
            end

            entries = Entries.new

            info["files"].each do |file|
              begin
                h = load_json_or_error("#{directory}/#{file}")
              rescue Oj::ParseError
                raise "#{directory}/#{file} is readable, but not parsable.   Please run the json through a linter."
              end

              entries.add Entry.create(fields: Fields.create_from_data(data: h[:entry], xmlns: h[:xmlns]))
            end

            @user = user

            true
          end

          # merge two images together
          #
          # @param other_image [Image] Image to merge from
          # @return [Cts::Mpx::Aci::Tasks::Image] new image containg merged results.
          def merge(other_image)
            raise 'an image class must be supplied' unless other_image.is_a? Image
            raise 'cannot merge if the user is different' unless other_image.user == user
            raise 'cannot merge if the account_id is different' unless other_image.account_id == account_id
            raise 'cannot merge if the state is different' unless other_image.state == state

            new_image = Image.new
            new_image.user = @user
            new_image.entries = entries + other_image.entries
            new_image
          end

          # transform an image to an abstract state
          def transform
            entries.each { |entry| entry.transform user }
            @state = :transformed
            @account_id = nil
            true
          end

          # untransform an image from an abstract state
          # @param target_account [String] account_id to transform to
          def untransform(target_account)
            entries.each do |entry|
              entry.fields['ownerId'] = target_account
              entry.untransform user, target_account
            end

            @state = :untransformed
            @account_id = target_account
            true
          end

          private

          def load_json_or_error(file)
            Oj.load File.read file
          rescue Oj::ParseError => exception
            raise "#{exception.message.split(' [').first}: #{file}"
          end
        end
      end
    end
  end
end
