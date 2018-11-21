require 'spec_helper'

module Cts
  module Mpx
    describe Entries do
      let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
      let(:carpe_diem_field) { Field.create name: "guid", value: "carpe diem" }
      let(:custom_field) { Field.create name: "$ref", value: "http://data.media.theplatform.com/data/Media/1", xmlns: { 'custom' => 'ref' } }
      let(:endpoint) { 'Media' }
      let(:entry) { Entry.create service: service, endpoint: endpoint, id: id, fields: Fields.create(collection: [guid_field, custom_field, carpe_diem_field]) }
      let(:guid_field) { Field.create name: "ref", value: "http://data.media.theplatform.com/data/Media/1" }
      let(:id) { 'http://data.media.theplatform.com/data/Media/1' }
      let(:service) { 'Media Data Service' }
      let(:user) { User.create username: 'a', password: 'b', token: 'token' }
      let(:entries) { described_class.new }

      before { entries.add entry }

      specify { expect(entries).to respond_to(:transform).with(1).arguments }
      specify { expect(entries).to respond_to(:untransform).with(2).arguments }
      specify { expect(entries).to respond_to(:files).with(0).arguments }

      describe ".transform" do
        context "when the entries has an entry" do
          before do
            allow(entries.first).to receive(:transform)
            entries.transform user
          end

          it { expect(entries.first).to have_received(:transform).with(user) }
        end
      end

      describe ".untransform" do
        context "when the entries has an entry" do
          before do
            allow(entries.first).to receive(:untransform)
            entries.untransform(user, id)
          end

          it { expect(entries.first).to have_received(:untransform).with(user, id) }
        end
      end

      describe ".files" do
        let(:result) { entries.files }

        it { expect(result).to be_instance_of Hash }

        context "when the entry guid is 'media_abcd'" do
          it { expect(result).to have_key(entry.filepath) }
        end
      end
    end
  end
end
