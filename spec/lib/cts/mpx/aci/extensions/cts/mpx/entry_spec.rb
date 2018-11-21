require 'spec_helper'

module Cts
  module Mpx
    describe Entry do
      let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
      let(:endpoint) { 'Media' }
      let(:guid) { 'carpe_diem' }
      let(:id) { 'http://data.media.theplatform.com/data/Media/1' }
      let(:image_directory) { 'tmp' }
      let(:service) { 'Media Data Service' }

      let(:entry) { Entry.create(id: id, fields: fields) }
      let(:fields) { Fields.create_from_data(data: { id: id, guid: guid, ref: id }) }
      let(:user) { User.create username: 'a', password: 'b', token: 'token' }

      let(:page) { Driver::Page.create entries: [{ id: id, guid: guid }] }
      let(:response) { Driver::Response.new }
      let(:query) { Query.new }
      let(:custom_field) { Field.create(name: custom_field_name, value: 'abcdef', xmlns: { "custom" => "http://1234a.com" }) }
      let(:custom_field_name) { 'custom$guid' }

      before do
        allow(Query).to receive(:new).and_return(query)
        allow(query).to receive(:run).and_return(response)
        allow(response).to receive(:status).and_return(200)
        response.instance_variable_set :@page, page
        entry.id = entry.fields['id']
      end

      describe "Instance method signatures" do
        it { is_expected.to respond_to(:dependencies).with(0).arguments }
        it { is_expected.to respond_to(:diff).with(1).arguments }
        it { is_expected.to respond_to(:directory).with(0).arguments }
        it { is_expected.to respond_to(:exists_by?).with(2).arguments }
        it { is_expected.to respond_to(:filename).with(0).arguments }
        it { is_expected.to respond_to(:filepath).with(0).arguments }
        it { is_expected.to respond_to(:hash).with(0).arguments }
        it { is_expected.to respond_to(:includes_reference?).with(0).arguments }
        it { is_expected.to respond_to(:includes_transformed_reference?).with(0).arguments }
        it { is_expected.to respond_to(:transform).with(1).arguments }
        it { is_expected.to respond_to(:untransform).with(2).arguments }
      end

      describe "#dependencies" do
        it { expect(entry.dependencies).to be_instance_of Array }

        context "when the reference is an account" do
          it "is expected to not include an account reference" do
            expect(entry.dependencies).not_to include("http://access.auth.theplatform.com/access/data/Account/1")
          end
        end

        it "is expected to return an array with long form id's" do
          expect(entry.dependencies).to eq [entry.fields['ref']]
        end

        it "is expected to return only unique entries" do
          entry.fields.add Field.create name: "ref", value: "http://data.media.theplatform.com/data/Media/1"
          expect(entry.dependencies).to eq [entry.fields['ref']]
        end
      end

      describe "#diff" do
        let(:other_entry) { described_class.create service: service, endpoint: endpoint, id: id, fields: fields }

        it { expect(entry.diff(other_entry)).to be_instance_of String }

        it "is expected to call Diffy to generate the diff" do
          allow(Diffy::Diff).to receive(:new).and_call_original
          entry.diff(other_entry)
          expect(Diffy::Diff).to have_received(:new)
        end

        context "when the argument is not an image" do
          it "is expected to raise an argument exception with a message an entry must be supplied" do
            allow(entry).to receive(:diff).and_call_original
            expect { entry.diff("") }.to raise_error(ArgumentError, /an entry must be supplied/)
          end
        end

        context "when the entries do not have the same service" do
          before { other_entry.id = "http://data.task.theplatform.com/task/data/Task/1" }

          it "will raise an exception with a message both entries must have the same service" do
            allow(entry).to receive(:diff).and_call_original
            expect { entry.diff(other_entry) }.to raise_error(ArgumentError, /both entries must have the same service/)
          end
        end

        context "when the entries do not have the same endpoint" do
          before { other_entry.id = "http://data.media.theplatform.com/media/data/Server/2" }

          it "will raise an exception with a message both entries must have the same endpoint" do
            allow(entry).to receive(:diff).and_call_original
            expect { entry.diff(other_entry) }.to raise_error(ArgumentError, /both entries must have the same endpoint/)
          end
        end
      end

      describe "#directory" do
        it { expect(entry.directory).to eq "#{entry.service}/#{entry.endpoint}" }
      end

      describe "#exists_by?" do
        let(:page) { Driver::Page.new }

        it "is expected to call query.run" do
          allow(query).to receive(:run).and_return(response)
          entry.exists_by?(user, query)
          expect(query).to have_received(:run).with(user: user)
        end

        it { expect(entry.exists_by?(user, query)).to be false }

        context "when the user is not signed in" do
          let(:user) { User.new }

          it { expect { entry.exists_by?(user, query) }.to raise_error(ArgumentError, /user must be signed in/) }
        end

        context "when the query is not a type of Query" do
          it { expect { entry.exists_by?(user, nil) }.to raise_error(ArgumentError, /query must be a type of Query/) }
        end

        context "when the query comes back with any results" do
          let(:page) { Driver::Page.create entries: [{ id: id, guid: guid }] }

          before { query.instance_variable_set :@page, page }

          it { expect(entry.exists_by?(user, query)).to be true }
        end
      end

      describe "#filename" do
        context "when the guid is 'carpe diem'" do
          it { expect(entry.filename).to eq "#{entry.fields['guid']}.json" }
        end
      end

      describe "#filepath" do
        context "when the field 'guid' is not set" do
          before { entry.fields.remove 'guid' }

          it { expect { entry.filepath } .to raise_error RuntimeError, /guid/ }
        end

        context "when the directory is 'Media Data Service/Media' and the filename is 'abcd.json'" do
          it { expect(entry.filepath).to eq "#{entry.directory}/#{entry.filename}" }
        end
      end

      describe "#hash" do
        it "is expected to be a MD5 hash that equals entry.to_s" do
          expect(entry.hash).to eq Digest::MD5.hexdigest entry.to_s
        end
      end

      describe "#includes_reference?" do
        context "when a reference is present in an entry" do
          before { entry.id = 'http://data.media.theplatform.com/media/data/Media/2' }

          it { expect(entry.includes_reference?).to eq true }
        end

        context "when a reference is not present in an entry" do
          before do
            entry.fields.remove 'ref'
            entry.fields.remove '$ref'
          end

          it { expect(entry.includes_reference?).to eq false }
        end
      end

      describe "#includes_transformed_reference?" do
        let(:transformed_field_reference) { "urn:cts:aci:Media+Data+Service:MediaField:1:http://www.comcast.com$a_custom_field" }

        before { entry.fields['ref'] = transformed_field_reference }

        context "when a reference is present in an entry" do
          it { expect(entry.includes_transformed_reference?).to eq true }
        end

        context "when a transformed reference is not present in an entry" do
          before { entry.fields.remove 'ref' }

          it { expect(entry.includes_transformed_reference?).to eq false }
        end
      end

      shared_examples 'transformations' do |direction|
        let(:entry) { entry_from_direction direction }

        before do
          allow(Cts::Mpx::Aci::Transformations).to receive(:traverse_for).and_call_original
        end

        it "is expected to call traverse_for" do
          allow(Cts::Mpx::Aci::Transformations).to receive(:traverse_for).and_return({})
          call_transform user, entry, direction
          expect(Cts::Mpx::Aci::Transformations).to have_received(:traverse_for).with(instance_of(Hash), direction)
        end

        context "when a reference is found" do
          it "is expected to call #{direction}_reference" do
            allow(Cts::Mpx::Aci::Transformations).to receive("#{direction}_reference").and_return({})
            call_transform user, entry, direction
            expect(Cts::Mpx::Aci::Transformations).to have_received("#{direction}_reference").at_least(:once)
          end
        end

        context "when a field_reference is found" do
          it "is expected to call #{direction}_field_reference" do
            entry.fields['ref'].gsub!("Server", "ServerField")
            entry.fields['ref'].gsub!("Media:", "MediaField:")
            allow(Cts::Mpx::Aci::Transformations).to receive("#{direction}_field_reference").and_return({})
            call_transform user, entry, direction
            expect(Cts::Mpx::Aci::Transformations).to have_received("#{direction}_field_reference").at_least(:once)
          end
        end
      end

      shared_examples 'aci_exceptions' do |direction|
        let(:entry) { entry_from_direction direction }

        context "when the field guid is not set" do
          before { entry.fields.remove 'guid' }

          it { expect { entry.transform user } .to raise_error RuntimeError, /guid/ }
        end

        context "when the field ownerId is not set" do
          before { entry.fields.remove 'ownerId' }

          it { expect { entry.transform user } .to raise_error RuntimeError, /ownerId/ }
        end

        context "when the attribute user is not set" do
          it { expect { entry.transform nil } .to raise_error RuntimeError, /user/ }
        end
      end

      describe "#transform" do
        include_examples 'aci_exceptions', :transform
        include_examples 'transformations', :transform
      end

      describe "#untransform" do
        include_examples 'aci_exceptions', :untransform
        include_examples 'transformations', :untransform
      end

      def call_transform(user, entry, direction)
        if direction == :transform
          entry.send direction, user
        else
          entry.send direction, user, entry.id
        end
      end

      def entry_from_direction(direction)
        if direction == :transform
          described_class
            .create(id:       id, service:  service, endpoint: endpoint, fields: Fields.create_from_data(
              data: {
                "id"      => "http://data.media.theplatform.com/media/data/Media/1",
                "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
                "guid"    => 'media_abcd',
                "ref"     => "http://data.media.theplatform.com/media/data/Server/1"
              }
            ))
        else
          described_class
            .create(id:       id, service:  service, endpoint: endpoint, fields: Fields.create_from_data(
              data: {
                "id"      => "http://data.media.theplatform.com/media/data/Media/1",
                "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
                "guid"    => 'media_abcd',
                "ref"     => 'urn:cts:aci:Media+Data+Service:Media:1:guid'
              }
            ))
        end
      end
    end
  end
end
