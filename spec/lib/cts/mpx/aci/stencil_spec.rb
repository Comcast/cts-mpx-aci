require 'spec_helper'

module Cts
  module Mpx
    module Aci
      describe Stencil do
        let(:stencil) { Stencil.new }
        let(:string) { Oj.dump Parameters.stencil }

        describe "Attributes" do
          it { is_expected.to have_attributes(name: "") }
          it { is_expected.to have_attributes(original_url: "") }
          it { is_expected.to have_attributes(queries: a_kind_of(Array)) }
          it { is_expected.to have_attributes(schema: a_kind_of(Numeric)) }
        end

        describe "Class method signatures" do
          it { expect(described_class).to respond_to(:[]).with(1).argument }
          it { expect(described_class).to respond_to(:load).with(1).argument }
          it { expect(described_class).to respond_to(:load_file).with(1).argument }
          it { expect(described_class).to respond_to(:load_string).with(1).argument }
          it { expect(described_class).to respond_to(:load_url).with(1).argument }
        end

        describe "Instance method signatures" do
          it { is_expected.to respond_to(:to_collect).with_keywords(:user, :account_id) }
        end

        describe "self.#[] (addressable operator)" do
          let(:stencil) { Stencil.new }
          let(:available_stencils) { { Parameters.stencil['name'] => stencil } }

          before do
            described_class.class_variable_set(:@@available_stencils, available_stencils)
          end

          context "when no argument is provided" do
            it "is expected to return all available stencils" do
              expect(described_class[]).to eq(available_stencils)
            end
          end

          it "is expected to return the referenced stencil" do
            expect(described_class['test stencil']).to eq stencil
          end

          it "is expected to a kind of Hash" do
            expect(described_class['test stencil']).to be_a_kind_of Stencil
          end
        end

        describe "self.#load" do
          context "when the argument is a string" do
            it "is expected to call load_string" do
              allow(described_class).to receive(:load_string).and_return(stencil)
              described_class.load(string)
              expect(described_class).to have_received(:load_string).with string
            end
          end

          context "when the argument is a url" do
            let(:url) { 'http://www.theplatform.com' }

            it "is expected to call load_url with the url" do
              allow(described_class).to receive(:load_url).and_return(stencil)
              described_class.load(url)
              expect(described_class).to have_received(:load_url).with(url)
            end
          end

          it "is expected to call load_file" do
            allow(described_class).to receive(:load_file).and_return(stencil)
            described_class.load('file')
            expect(described_class).to have_received(:load_file).with('file')
          end
        end

        describe "self.#load_url" do
          let(:url) { 'http://www.theplatform.com' }
          let(:response) do
            response = Excon::Response.new
            response.body = string
            response
          end

          context "when the url is not a lexically equivalent URI (rfc 3986)" do
            let(:url) { 'this is not the greatest song in the world' }

            it "is expected to raise an argument exception" do
              expect { described_class.load_url(url) }.to raise_error(ArgumentError).with_message(/#{url} is not a url/)
            end
          end

          it "is expected to call Excon.get with the url" do
            allow(Excon).to receive(:get).and_return(response)
            described_class.load_url(url)
            expect(Excon).to have_received(:get).with(url)
          end

          it "is expected to call load_string with the body of the response" do
            allow(Excon).to receive(:get).and_return(response)
            allow(described_class).to receive(:load_string).and_return(stencil)
            described_class.load_url(url)
            expect(described_class).to have_received(:load_string).with(string)
          end
        end

        describe "self.#load_file" do
          let(:filename) { 'stencil.json' }

          before do
            allow(File).to receive(:exist?).with("stencil.json").and_return(true)
            allow(File).to receive(:read).with("stencil.json").and_return(string)
            allow(described_class).to receive(:load_string).and_return(stencil)
          end

          context "when the filename does not exist it" do
            it "is expected to raise_error with a message /Could not find file/" do
              allow(File).to receive(:exist?).with(filename).and_return(false)
              expect { described_class.load_file(filename) }.to raise_error RuntimeError, /Could not find file #{filename}./
            end
          end

          it "is expected to call load_string with the content of the file" do
            described_class.load_file(filename)
            expect(described_class).to have_received(:load_string).with(string)
          end

          it "is expected to store the filename in original_url" do
            described_class.load_file(filename)
            expect(stencil.original_url).to eq(filename)
          end
        end

        describe "#load_string" do
          let(:url) { 'http://localhost/file.json' }

          it "is expected to return a Stencil" do
            expect(described_class.load_string(string)).to be_a_kind_of(Stencil)
          end

          it "is expected to instantiate a new instance of #{described_class}" do
            allow(described_class).to receive(:new).and_return(Stencil.new)
            described_class.load_string(string)
            expect(described_class).to have_received(:new)
          end

          context "when the argument is not a kind of String" do
            [//, [], 1, 0.0, {}, nil].each do |type|
              it "is expected raise an argumentError with a message including '#{type.class} not a kind of String'" do
                expect { described_class.load_string(type) }.to raise_error(ArgumentError).with_message(/#{type.class} is not a kind of String/)
              end
            end
          end

          context "when the JSON cannot be parsed" do
            it "is expected to raise a RuntimeError with a message including 'could not be parsed'" do
              expect { described_class.load_string("]") }.to raise_error(ArgumentError).with_message(/could not be parsed/)
            end
          end

          context "when the stencil is not in the available stencils" do
            it "is expected to be added" do
              expect { described_class.load_string(string) }.to change(described_class, :[])
            end
          end
        end

        describe "#to_collect" do
          let(:stencil) { Stencil.create name: "test stencil", queries: [{}] }
          let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
          let(:collect) { Tasks::Collect.new }

          it { expect(stencil.to_collect.class).to eq Tasks::Collect }

          it "is expected to call Query.new" do
            allow(Query).to receive(:new).and_call_original
            stencil.to_collect
            expect(Query).to have_received(:new).exactly :once
          end

          it "is expected to add the query to collect.queries" do
            allow(Tasks::Collect).to receive(:new).and_return(Tasks::Collect.new)
            expect { stencil.to_collect }.to change(collect, :queries).to([a_kind_of(Query)])
          end

          context "when an account_id is provided" do
            it "is expected to set the collect.account_id with the parameter" do
              expect(stencil.to_collect(account_id: account_id).account_id).to eq account_id
            end
          end

          context "when a user is provided" do
            let(:user) { User.new }

            it "is expected to set collect.user with the parameter" do
              expect(stencil.to_collect(user: user).user).to eq user
            end
          end

          context "when no queries are provided" do
            before { stencil.queries = [] }

            it "is expected to return nil" do
              expect { stencil.to_collect }.to raise_error.with_message(/queries must contain entries/)
            end
          end
        end
      end
    end
  end
end
