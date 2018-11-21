require 'spec_helper'

module Cts
  module Mpx
    describe Aci do
      describe "Class method signatures" do
        it { expect(described_class).to respond_to(:logger) }
        it { expect(described_class).to respond_to(:options) }
      end

      describe "::logger" do
        it "is expected to return a Logger object" do
          expect(described_class.logger).to be_a_kind_of Logging::Logger
        end
      end

      describe "::options" do
        let(:option_keys) { %i[log_to_stdout log_to_file colorize_stdout] }

        context "when no argument is provided" do
          it "is expected to return all options" do
            expect(described_class.options).to include(*option_keys)
          end
        end

        context "when a parameter is passed in" do
          it "is expected to return the referenced option" do
            expect(described_class.options[:log_to_stdout]).to be false
          end
        end

        shared_examples 'option_keys' do |key|
          it "is expected to contain the key #{key}" do
            expect(described_class.options[key]).not_to be_nil
          end
        end

        %i[log_to_stdout log_to_file colorize_stdout].each { |key| include_examples 'option_keys', key }
      end

      describe "::configure_options" do
        before do
          allow(Aci.logger).to receive(:add_appenders).and_return('')
          Aci.logger.clear_appenders
          Aci.options.each_key { |k| Aci.options[k] = false }
        end

        context "when the option log_to_file is set" do
          it "is expected to call add_appenders with :file as the argument" do
            # this is here to block the physical file from being created.
            allow(Logging::Appenders::File).to receive(:new).and_return('')
            Aci.options[:log_to_file] = true
            described_class.configure_options
            expect(Aci.logger).to have_received(:add_appenders)
          end
        end

        context "when the option log_to_stdout is set" do
          it "is expected to log to add_appenders with :stdout as the argument" do
            Aci.options[:log_to_stdout] = true
            described_class.configure_options
            expect(Aci.logger).to have_received(:add_appenders).with Logging::Appenders::Stdout
          end
        end

        context "when the option colorize_stdout is set" do
          before do
            allow(Aci.logger).to receive(:add_appenders).and_call_original
            Aci.options[:colorize_stdout] = true
            described_class.configure_options
          end

          it "is expected to log to add_appenders with :stdout as the argument" do
            expect(Aci.logger).to have_received(:add_appenders).with Logging::Appenders::Stdout
          end

          it "is expected to log to stdout in color" do
            expect(Aci.logger.appenders.last.layout.color_scheme).not_to be_nil
          end
        end
      end
    end
  end
end
