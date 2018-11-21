require 'spec_helper'

module Cts
  module Mpx
    module Aci
      describe Validators do
        specify { expect(described_class).to respond_to(:image_directory?).with(1).arguments }
        specify { expect(described_class).to respond_to(:info_file?).with(1).arguments }
        specify { expect(described_class).to respond_to(:image_deployable?).with(1).arguments }
        specify { expect(described_class).to respond_to(:reference?).with(1).arguments }
        specify { expect(described_class).to respond_to(:transformed_reference?).with(1).arguments }

        describe '#image_directory?' do
          let(:result) { described_class.image_directory?('.') }

          before { allow(File).to receive(:exist?).with('./info.json').and_return(true) }

          it { expect(result).to eq true }

          context "when the info file does not exist" do
            before { allow(File).to receive(:exist?).with('./info.json').and_return(false) }

            it { expect(result).to eq false }
          end
        end

        describe "#info_file?" do
          let(:result) { described_class.info_file?('info.json') }

          before do
            allow(File).to receive(:exist?).with('info.json').and_return(true)
            allow(File).to receive(:read).with('info.json').and_return('{}')
          end

          context "when the info.json file does not exist" do
            before { allow(File).to receive(:exist?).with('info.json').and_return(false) }

            it { expect { result }.to raise_error(RuntimeError, /could not find an info.json/) }
          end

          context "when it is not parsable json" do
            before { allow(File).to receive(:read).with('info.json').and_return('.') }

            it { expect(result).to be false }
          end

          it { expect(result).to be true }
        end

        describe "#image_deployable?" do
          let(:image) { Tasks::Image.create entries: Entries.create(collection: [entry]) }
          let(:entry) { Entry.new }
          let(:user) { User.create username: 'a', password: 'b', token: 'token' }

          let(:subject) { described_class.image_deployable?(image) }

          before { entry.fields['ref'] = nil }

          it { expect(described_class.image_deployable?(image)).to be true }

          context "when any reference equals 'urn:cts:aci:no-id-found'" do
            before { entry.fields['ref'] = 'urn:cts:aci:no-id-found' }

            it { is_expected.to be false }
          end

          context "when any reference equals 'urn:cts:aci:no-guid-found'" do
            before { entry.fields['ref'] = 'urn:cts:aci:no-guid-found' }

            it { expect(described_class.image_deployable?(image)).to be false }
          end

          context "when the image is transformed" do
            before { image.instance_variable_set '@state', :transformed }

            it { expect(described_class.image_deployable?(image)).to be false }
          end

          context "when the image does not have any entries" do
            before { image.entries = Entries.new }

            it { expect(described_class.image_deployable?(image)).to be false }
          end
        end

        describe "#reference?" do
          let(:reference) { "http://data.media.theplatform.com/media/data/Media/1" }

          context "when the reference is not a lexically equivalent URI (rfc 3986)" do
            before { reference.gsub!('http', 'htt p') }

            it { expect(described_class.reference?(reference)).to eq false }
          end

          context "when the reference scheme is not http or https" do
            before { reference.gsub!('http', 'ftp') }

            it { expect(described_class.reference?(reference)).to eq false }
          end

          context "when the reference host does not end with .theplatform.com" do
            before { reference.gsub!('theplatform', 'nottheplatform') }

            it { expect(described_class.reference?(reference)).to eq false }
          end

          # TODO: check this out, see if I need it.   I may have decided to drop references and directly use the cts-mpx namespace by then.
          # context "when reference path does not end with digits" do
          #   before { reference.gsub!('1', 'abc') }
          #   it { expect(described_class.reference?(reference)).to eq false }
          # end

          context "when the reference host is `web.theplatform.com`" do
            it { expect(described_class.reference?('http://web.theplatform.com')).to eq false }
          end

          context "when the reference host is a feed `feed.media.theplatform`" do
            it { expect(described_class.reference?('http://feed.media.theplatform.com')).to eq false }
          end

          it { expect(described_class.reference?(reference)).to eq true }
        end

        describe "#transformed_reference?" do
          let(:transformed_reference) { 'urn:cts:aci:Media+Data+Service:Media:1:guid' }

          context "when the reference is not a lexically equivalent URN (rfc 2141)" do
            before { transformed_reference.gsub!('urn', 'nru') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the namespace identifier is not cts" do
            before { transformed_reference.gsub!('cts', 'tsi') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the nss segment 1 is not equal to aci" do
            before { transformed_reference.gsub!('aci', 'ica') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the nss segment 2 is not equal to a service name" do
            before { transformed_reference.gsub!('Media+Data+Service', 'service') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the nss segment 3 is not an endpoint" do
            before { transformed_reference.gsub!(':Media:', ':NotMedia:') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the nss segment 4 is not a series of digits" do
            before { transformed_reference.gsub!('1', 'abcdef') }

            it { expect(described_class.transformed_reference?(transformed_reference)).to be false }
          end

          context "when the reference is 'urn:cts:aci:no-id-found'" do
            it { expect(described_class.transformed_reference?('urn:cts:aci:no-id-found')).to be true }
          end

          context "when the reference is 'urn:cts:aci:no-guid-found'" do
            it { expect(described_class.transformed_reference?('urn:cts:aci:no-guid-found')).to be true }
          end

          context "when the reference is 'urn:cts:aci:no-custom-field-found'" do
            it { expect(described_class.transformed_reference?('urn:cts:aci:no-guid-found')).to be true }
          end

          context "when the reference is 'urn:cts:aci:target-account'" do
            it { expect(described_class.transformed_reference?('urn:cts:aci:target-account')).to eq true }
          end

          it { expect(described_class.transformed_reference?(transformed_reference)).to eq true }
        end

        describe "#transformed_field_reference?" do
          let(:transformed_field_reference) { 'urn:cts:aci:Media+Data+Service:MediaField:1:guid' }

          context "when the nss segment 3 does not end with Field" do
            before { transformed_field_reference.gsub!(':MediaField:', ':NotMedia:') }

            it { expect(described_class.transformed_field_reference?(transformed_field_reference)).to be false }
          end

          it { expect(described_class.transformed_field_reference?(transformed_field_reference)).to eq true }
        end
      end
    end
  end
end
