require 'spec_helper'

module Cts
  module Mpx
    module Aci
      module Tasks
        describe Image do
          let(:entries) { Entries.new }
          let(:entry) { Entry.new }
          let(:image) { Image.new }
          let(:user) { User.create username: 'a', password: 'b', token: 'token' }
          let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }

          describe "Attributes" do
            it { is_expected.to have_attributes(account_id: "") }
            it { is_expected.to have_attributes(entries: a_kind_of(Entries)) }
            it { is_expected.to have_attributes(date_taken: a_kind_of(Time)) }
            it { is_expected.to have_attributes(state: :untransformed) }
            it { is_expected.to have_attributes(user: nil) }
            it { is_expected.to have_attributes(schema: 1) }
          end

          describe "Class methods" do
            it { expect(described_class).to respond_to(:load_from_directory).with(2).arguments }
          end

          describe "Instance Methods" do
            it { is_expected.to respond_to(:entries).with(0).arguments }
            it { is_expected.to respond_to(:files).with(0).arguments }
            it { is_expected.to respond_to(:load_from_directory).with(2).arguments }
            it { is_expected.to respond_to(:save_to_directory).with(1).arguments }
            it { is_expected.to respond_to(:transform).with(0).arguments }
            it { is_expected.to respond_to(:untransform).with(1).arguments }
            it { is_expected.to respond_to(:info).with(0).arguments }
            it { is_expected.to respond_to(:merge).with(1).arguments }
          end

          describe "#self.load_from_directory" do
            before do
              allow(described_class).to receive(:new).and_return(image)
              allow(image).to receive(:load_from_directory).and_return true
            end

            it { expect(image.load_from_directory('tmp')).to be true }
            it { expect(described_class.load_from_directory('tmp')).to be_instance_of described_class }

            it "is expected to call image.load_from_directory" do
              image.load_from_directory('tmp')
              expect(image).to have_received(:load_from_directory)
            end
          end

          describe "#files" do
            let(:filepath) { '//file/path/name.json' }

            before do
              allow(entry).to receive(:filepath).and_return(filepath)
              image.entries = entries.add entry
            end

            it { expect(image.files).to be_instance_of Array }
            it { expect(image.files).to all(be_a_kind_of(String)) }

            it "is expected to return a map of each entries #files method" do
              expect(image.files).to eq [filepath]
            end
          end

          describe "#info" do
            before { image.user = user }

            it { expect(image.info).to be_instance_of Hash }

            %i[schema state files].each do |param|
              it "is expected to have key :#{param} eq image.#{param}" do
                expect(image.info[param]).to eq image.send(param)
              end
            end

            it "is expected to have key :date_taken to eq an ISO-8601 formatted date." do
              expect(image.info[:date_taken]).to match image.date_taken.iso8601
            end

            it "is expected to not contain any other keys" do
              expect(image.info.keys).to eq %i[account_id date_taken username schema state files]
            end

            context "when the user is provided" do
              it "is expected to have key :username to the username of mpx user that recorded it" do
                expect(image.info[:username]).to eq image.user.username
              end
            end
          end

          describe "#load_from_directory" do
            let(:endpoint) { 'Media' }
            let(:guid) { 'carpe_diem' }
            let(:id) { 'http://data.media.theplatform.com/data/Media/1' }
            let(:image_directory) { 'tmp' }
            let(:service) { 'Media Data Service' }

            let(:fields) { Fields.create_from_data(data: { id: id, guid: guid }) }
            let(:entry) { Entry.create(id: id, fields: fields) }
            let(:image) { Image.create(account_id: account_id, user: user, entries: Entries.create(collection: [entry])) }

            before do
              entry.id = entry.fields['id']
              allow(Validators).to receive(:image_directory?).and_return(true)
              allow(Image).to receive(:new).and_return image
              allow(image).to receive(:load_json_or_error).with('tmp/info.json').and_return(Oj.load(image.info.to_json))
              allow(image).to receive(:load_json_or_error).with("tmp/#{service}/#{endpoint}/#{guid}.json").and_return(entry.to_h)
            end

            %i[user state account_id schema date_taken].each do |field|
              it "is expected to change #{field}" do
                image.instance_variable_set "@#{field}", nil
                expect { image.load_from_directory(image_directory, user) }.to change(image, field)
              end
            end

            context "when the image_directory validator returns false" do
              before { allow(Validators).to receive(:image_directory?).and_return(false) }

              it "is expected to raise an exception with a message including the directory" do
                expect { image.load_from_directory(image_directory, user) }.to raise_error(RuntimeError, /#{image_directory}/)
              end
            end

            context "when an entry file is not parsable" do
              before { allow(image).to receive(:load_json_or_error).with("#{image_directory}/#{entry.filepath}").and_raise(Oj::ParseError) }

              it "is expected to raise an exception with a message including the entry.filepath" do
                expect { image.load_from_directory(image_directory, user) }.to raise_error(RuntimeError, /#{image_directory}\/#{entry.filepath}/)
              end
            end
          end

          describe "#merge" do
            let(:image) { Image.create user: user, entries: Entries.create(collection: [entry]) }
            let(:other_image) { Image.create user: user, entries: Entries.create(collection: [entry]) }
            let(:merged_image) { image.merge other_image }

            it { expect(merged_image).to be_instance_of Image }

            it "is expected to merge the entries of each image together." do
              expect(merged_image.entries.entries.count).to eq 2
            end

            it "is expected to update date_taken to the current time." do
              # datetime is to the nanosecond, iso8601 is not.
              expect(merged_image.date_taken.iso8601).to eq Time.now.iso8601
            end

            context "when the argument supplied is not a #{described_class}." do
              it "is expected to raise a ArguementError exception with message an image class must be supplied" do
                expect { image.merge false }.to raise_error(RuntimeError, 'an image class must be supplied')
              end
            end

            shared_examples "attributes_are_different" do |attribute|
              context "when the #{attribute}s are different" do
                before do
                  if attribute == "user"
                    other_image.instance_variable_set "@#{attribute}", User.create(username: 'b', password: 'b', token: 'token')
                  else
                    other_image.instance_variable_set "@#{attribute}", nil
                  end
                end

                it "is expected to raise an exception with a message cannot merge if the #{attribute} is different" do
                  expect { image.merge other_image }.to raise_error(RuntimeError, "cannot merge if the #{attribute} is different")
                end
              end
            end

            ["user", "account_id", "state"].each do |attribute|
              include_examples "attributes_are_different", attribute
            end
          end

          describe "#save_to_directory" do
            let(:image_directory) { 'tmp' }

            before do
              allow(File).to receive(:write).with(any_args).and_return 0
              image.save_to_directory(image_directory)
            end

            it { expect(image.save_to_directory(image_directory)).to be true }

            it "is expected to call File.write with each entry in image.entries" do
              image.entries.each { |entry| expect(File).to have_received(:write).with("#{image_directory}/#{entry.filepath}", anything) }
            end

            it "is expected to call File.write with info.json" do
              expect(File).to have_received(:write).with("#{image_directory}/info.json", anything)
            end
          end

          describe "#schema" do
            let(:current_schema) { 1 }

            it { expect(image.schema).to be_a_kind_of Integer }

            it "is expected to return it's current schema version." do
              expect(image.schema).to be current_schema
            end
          end

          describe "#transform" do
            let(:image) { Image.create user: user, entries: Entries.create(collection: [entry]) }

            before do
              image.entries.each { |c| allow(c).to receive :transform }
            end

            it { expect { image.transform }.to change(image, :account_id).to nil }
            it { expect { image.transform }.to change(image, :state).to :transformed }
          end

          describe "#untransform" do
            let(:image) { Image.create user: user, entries: Entries.create(collection: [entry]) }

            before do
              image.entries.each { |c| allow(c).to receive :transform }
              image.transform
              image.entries.each { |c| allow(c).to receive :untransform }
            end

            it { expect { image.untransform account_id }.to change(image, :account_id).to a_kind_of(String) }
            it { expect { image.untransform account_id }.to change(image, :state).to :untransformed }
          end
        end
      end
    end
  end
end
