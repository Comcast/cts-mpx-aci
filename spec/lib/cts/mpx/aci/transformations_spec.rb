require 'spec_helper'

module Cts
  module Mpx
    module Aci
      describe Transformations do
        let(:target_account) { 'urn:cts:aci:target-account' }
        let(:user) { User.create username: 'a', password: 'b', token: 'token' }
        let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
        let(:body) { Oj.dump page_hash }
        let(:endpoint) { 'Media' }
        let(:entry) { described_class.create service: service, endpoint: endpoint, id: id, fields: Fields.create(collection: [guid_field, ref_field, custom_field]) }
        let(:custom_field) { Field.create name: "$ref", value: "http://www.comcast.com", xmlns: { 'custom' => 'a_custom_field' } }
        let(:excon_response) { Excon::Response.new body: body, status: 200 }
        let(:guid) { 'carpe_diem' }
        let(:id) { 'http://data.media.theplatform.com/data/Media/161' }
        let(:page_hash) { { "entries" => [{ "id" => id, "ownerId" => account_id, "guid" => guid, "ref" => reference }] } }
        let(:params) { { user: user, original_account: account_id, reference: reference } }
        let(:ref_field) { Field.create name: "ref", value: reference }
        let(:reference) { 'http://data.media.theplatform.com/data/Media/1' }
        let(:request) { Driver::Request.new }
        let(:response) { Cts::Mpx::Driver::Response.create original: excon_response }
        let(:service) { 'Media Data Service' }
        let(:transformed_reference) { "urn:cts:aci:Media+Data+Service:Media:1:carpe_diem" }

        before do
          allow(Services::Data).to receive(:get).and_return response
          allow(Driver::Request).to receive(:new).and_return request
          allow(request).to receive(:call).and_return response
        end

        it { is_expected.to respond_to(:traverse_for).with(2).arguments }
        it { is_expected.to respond_to(:transform_reference).with_keywords(:reference, :user, :original_account) }
        it { is_expected.to respond_to(:transform_field_reference).with_keywords(:field_reference, :user) }
        it { is_expected.to respond_to(:untransform_reference).with_keywords(:transformed_reference, :user, :target_account) }
        it { is_expected.to respond_to(:untransform_field_reference).with_keywords(:transformed_field_reference, :user) }

        describe "#transform_reference" do
          it "is expected to return a transformed reference" do
            expect(described_class.transform_reference(params)).to eq transformed_reference
          end

          context "when reference is not a transformed_reference it" do
            before { params[:reference] = 'not_a_reference' }

            it "is expected to return the supplied argument" do
              expect(described_class.transform_reference(params)).to eq 'not_a_reference'
            end
          end

          context "when the reference:ownerId is the same as the entry:ownerId (account object)" do
            before { params[:reference] = account_id }

            it "is expected to return urn:cts:aci:target-account" do
              expect(described_class.transform_reference(params)).to eq 'urn:cts:aci:target-account'
            end
          end

          context "when the entry could not be looked up" do
            let(:page_hash) { { "entries" => [] } }

            it { expect(described_class.transform_reference(params)).to eq "urn:cts:aci:no-id-found" }
          end

          context "when it could not look up the guid" do
            let(:page_hash) { { "entries" => [{ "id" => id, "ownerId" => account_id, "ref" => reference }] } }

            it { expect(described_class.transform_reference(params)).to eq "urn:cts:aci:no-guid-found" }
          end
        end

        describe "#transform_field_reference" do
          subject { :reference }

          let(:page_hash) do
            { "namespace" => 'http://www.comcast.com',
              "entries"   => [
                { 'fieldName' => 'a_custom_field', "id" => id, "ownerId" => account_id, "guid" => guid, "ref" => reference }
              ] }
          end
          let(:reference) { "http://data.media.theplatform.com/media/data/MediaField/1" }
          let(:transformed_field_reference) { "urn:cts:aci:Media+Data+Service:MediaField:1:http://www.comcast.com$a_custom_field" }
          let(:field_reference_hash) { { user: user, field_reference: reference } }

          it do
            expect(described_class.transform_field_reference(field_reference_hash)).to eq transformed_field_reference
          end

          context "when reference is not a transformed_field_reference it" do
            it "is expected to return the supplied argument" do
              field_reference_hash[:field_reference] = 'not_a_field_reference'
              expect(described_class.transform_field_reference(field_reference_hash)).to eq 'not_a_field_reference'
            end
          end

          context "when it could not look up the entry" do
            let(:page_hash) { { "entries" => [] } }

            it "is expected to return urn:cts:aci:no-id-found" do
              expect(described_class.transform_field_reference(field_reference_hash)).to eq "urn:cts:aci:no-id-found"
            end
          end

          context "when it could not look up the qualified field name" do
            let(:page_hash) { { "entries" => [{ "id" => id, "ownerId" => account_id, "ref" => reference }] } }

            it "is expected to return the value to urn:cts:aci:no-qualified-field-name-found" do
              expect(described_class.transform_field_reference(field_reference_hash)).to eq "urn:cts:aci:no-qualified-field-name-found"
            end
          end
        end

        describe "#untransform_reference" do
          let(:transformed_reference) { "urn:cts:aci:Media+Data+Service:Media:1:media_abcd" }
          let(:transformed_field_reference) { "urn:cts:aci:Media+Data+Service:MediaField:1:http://www.comcast.com$a_custom_field" }
          let(:reference_hash) { { user: user, target_account: account_id, transformed_reference: transformed_reference } }

          it "is expected to return a reference" do
            expect(described_class.untransform_reference(reference_hash)).to eq id
          end

          context "when the transformed_reference is 'urn:cts:aci:target-account'" do
            it "is expected to return the account" do
              reference_hash[:transformed_reference] = 'urn:cts:aci:target-account'
              expect(described_class.untransform_reference(reference_hash)).to eq account_id
            end
          end

          context "when transformed_reference it is not a transformed reference" do
            it "is expected to return the original transformed_reference" do
              reference_hash[:transformed_reference] = 'not_a_transformed_reference'
              expect(described_class.untransform_reference(reference_hash)).to eq 'not_a_transformed_reference'
            end
          end

          context "when more than one entry by guid is returned" do
            let(:page_hash) do
              { "entries" => [{ "id" => id, "ownerId" => account_id, "ref" => reference },
                              { "id" => reference, "ownerId" => account_id, "ref" => id }] }
            end

            it "is expected to raise_error with a message /service returned too many entries on guid/" do
              expect { described_class.untransform_reference(reference_hash) }.to raise_error RuntimeError, /service returned too many entries on guid/
            end
          end

          context "when it could not look up the entry by guid" do
            let(:page_hash) { { "entries" => [] } }

            it "is expected to raise_error with a message /could not find an entry by guid/" do
              expect { described_class.untransform_reference(reference_hash) }.to raise_error RuntimeError, /could not find an entry by guid/
            end
          end
        end

        describe "#untransform_field_reference" do
          let(:transformed_field_reference) { "urn:cts:aci:Media+Data+Service:MediaField:1:http://www.comcast.com$a_custom_field" }
          let(:field_reference_hash) { { user: user, target_account: account_id, transformed_field_reference: transformed_field_reference } }
          let(:field_reference) { "http://data.media.theplatform.com/media/data/MediaField/1" }
          let(:page_hash) { { "entries" => [{ "id" => field_reference, "ownerId" => account_id, "guid" => guid, "ref" => field_reference }] } }

          it "is expected to return a field_reference" do
            expect(described_class.untransform_field_reference(field_reference_hash)).to eq field_reference
          end

          context "when transformed_field_reference it is not a transformed field_reference" do
            it "is expected to return the original transformed_field_reference" do
              field_reference_hash[:transformed_field_reference] = 'not_a_transformed_field_reference'
              expect(described_class.untransform_field_reference(field_reference_hash)).to eq 'not_a_transformed_field_reference'
            end
          end

          context "when more than one entry by qualified field name is returned" do
            let(:page_hash) { { "entries" => [{ "id" => field_reference, "ownerId" => account_id, "guid" => guid, "ref" => field_reference }, { "id" => field_reference, "ownerId" => account_id, "guid" => guid, "ref" => field_reference }] } }

            it "is expected to raise_error with a message /service returned too many entries on qualified field name/" do
              expect { described_class.untransform_field_reference(field_reference_hash) }.to raise_error RuntimeError, /service returned too many entries on qualified field name/
            end
          end

          context "when it could not look up the entry by qualified field name" do
            let(:page_hash) { { "entries" => [] } }

            it "is expected to raise_error with a message /could not find an entry by qualified field name/" do
              expect { described_class.untransform_field_reference(field_reference_hash) }.to raise_error RuntimeError, /could not find an entry by qualified field name/
            end
          end
        end

        describe "#traverse_for" do
          shared_examples 'traverse_for_bidirectional_test' do |direction|
            if direction == :transform
              method_name = :reference?
              entry = Cts::Mpx::Spec::Parameters.untransformed_entry_traversal
            else
              method_name = :transformed_reference?
              entry = Cts::Mpx::Spec::Parameters.transformed_entry_traversal
            end

            it "is expected to call Validators.#{method_name}" do
              allow(Validators).to receive(method_name).and_call_original
              described_class.traverse_for(entry, direction) { |_field, value| value }
              expect(Validators).to have_received(method_name).at_least(:once)
            end

            context "when the id field is detected" do
              it { expect { described_class.traverse_for(entry, direction) { |a| a } }.not_to(change { entry['id'] }) }
            end

            context "when a untransformed reference is found" do
              it "is expected to yield control passing in the field name and the value" do
                expect { |b| described_class.traverse_for(entry, direction, &b) }.to yield_control
              end

              it "is expected to return a hash" do
                expect(described_class.traverse_for(entry, direction) { |_k, _v| 'new_value' }).to be_a Hash
              end

              it "is expected to traverse arrays looking for an untransformed_reference" do
                allow(Transformations).to receive(:traverse_array).and_call_original
                described_class.traverse_for(entry, direction) { nil }
                expect(Transformations).to have_received(:traverse_array).at_least(:once)
              end

              it "is expected to traverse hashes looking for an untransformed_reference" do
                allow(Transformations).to receive(:traverse_hash).and_call_original
                described_class.traverse_for(entry, direction) { nil }
                expect(Transformations).to have_received(:traverse_hash).at_least :once
              end

              context "when the array is not populated with strings it" do
                it "is expected to not call transform_hash" do
                  allow(Transformations).to receive(:traverse_hash).and_call_original
                  described_class.traverse_for(entry, direction) { nil }
                  expect(Transformations).not_to have_received(:traverse_hash).with([1, 2])
                end
              end

              context "when the array is populated with hashes" do
                it "is expected to call transform_hash" do
                  allow(Transformations).to receive(:traverse_hash).and_call_original
                  described_class.traverse_for(entry, direction) { nil }
                  expect(Transformations).not_to have_received(:traverse_hash).with([1, 2])
                end
              end

              context "when a hash has a sub hash" do
                it "is expected to call transform_hash" do
                  allow(Transformations).to receive(:traverse_hash).and_call_original
                  described_class.traverse_for(entry, direction) { nil }
                  expect(Transformations).not_to have_received(:traverse_hash).with([1, 2])
                end
              end
            end
          end

          context "when transforming" do
            include_examples 'traverse_for_bidirectional_test', :transform
          end

          context "when untransforming" do
            include_examples 'traverse_for_bidirectional_test', :untransform
          end
        end
      end
    end
  end
end
