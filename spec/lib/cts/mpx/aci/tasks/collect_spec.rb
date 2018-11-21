require 'spec_helper'

module Cts
  module Mpx
    module Aci
      module Tasks
        describe Collect do
          let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
          let(:id) { 'http://data.media.theplatform.com/data/Media/1' }
          let(:endpoint) { 'Media' }
          let(:service) { 'Media Data Service' }

          let(:collect) { Collect.create user: user, account_id: account_id, queries: queries }
          let(:entry) { Entry.create service: service, endpoint: endpoint, id: id }
          let(:queries) { [{ "service" => service, "endpoint" => endpoint }] }
          let(:query) { Query.create service: service, endpoint: endpoint }
          let(:user) { User.create username: 'a', password: 'b', token: 'token' }

          it { is_expected.to be_a_kind_of Creatable }

          it { is_expected.to have_attributes(entries: a_kind_of(Entries)) }
          it { is_expected.to have_attributes(user: a_value) }
          it { is_expected.to have_attributes(account_id: a_kind_of(String)) }
          it { is_expected.to have_attributes(queries: a_kind_of(Array)) }

          it { is_expected.to respond_to(:collect).with(0).arguments }
          it { is_expected.to respond_to(:queries=).with(1).arguments }

          describe "#collect" do
            let(:response) { Driver::Response.create status: 200 }
            let(:query) { Query.new }
            let(:entries) { Entries.create collection: [entry] }

            before do
              allow(Query).to receive(:new).and_return(query)
              allow(query).to receive(:run).and_return(query)
              allow(query).to receive(:entries).and_return(entries)
            end

            it "is expected to reset entries to a empty state" do
              allow(Entries).to receive(:new).and_call_original
              collect.collect
              expect(Entries).to have_received(:new).at_least :once
            end

            it "is expected to use Cts::Mpx::Query#run" do
              collect.collect
              expect(query).to have_received(:run).with(user: user)
            end

            it "is expected to add queried entries to Entries" do
              expect { collect.collect }.to change(collect, :entries)
            end

            it "is expected to call log.info" do
              allow(Aci.logger).to receive(:info).and_return nil
              collect.collect
              expect(Aci.logger).to have_received(:info).with(/#{entry.fields['id']}.*#{entry.fields['guid']}/)
            end

            %i[account_id user queries].each do |attribute|
              context "when the #{attribute} is not set" do
                before { collect.instance_variable_set("@#{attribute}", nil) }

                it { expect { collect.collect }.to raise_error(/must set the #{attribute} attribute./) }
              end
            end

            context "when an individual query does not have service set" do
              before { collect.queries.first['service'] = '' }

              it { expect { collect.collect }.to raise_error ArgumentError, /does not have service set/ }
            end

            context "when an individual query does not have endpoint set" do
              before { collect.queries.first['endpoint'] = '' }

              it { expect { collect.collect }.to raise_error ArgumentError, /does not have endpoint set/ }
            end

            context "when no results are returned" do
              before { allow(query).to receive(:page).and_return(nil) }

              it "is expected to call log.info with 'collected zero results'" do
                allow(Aci.logger).to receive(:info).and_return nil
                collect.collect
                expect(Aci.logger).to have_received(:info).with 'collected zero results for Media Data Service/Media'
              end

              it "is expected to have an empty entries object" do
                collect.collect
                expect(collect.entries.any?).to eq false
              end
            end
          end

          describe "#queries=" do
            context "when the argument is not an array" do
              it { expect { collect.queries = {} }.to raise_error ArgumentError }
            end

            context "when the array does not have hashes" do
              it { expect { collect.queries = [{}, [], {}] }.to raise_error ArgumentError }
            end
          end
        end
      end
    end
  end
end
