require 'spec_helper'

module Cts
  module Mpx
    module Aci
      module Tasks
        describe Deploy do
          let(:account_id) { "http://access.auth.theplatform.com/access/data/Account/1" }
          let(:endpoint) { 'Media' }
          let(:guid) { 'carpe_diem' }
          let(:id) { 'http://data.media.theplatform.com/data/Media/1' }
          let(:other_id) { 'http://data.task.theplatform.com/data/Task/1' }
          let(:image_directory) { 'tmp' }
          let(:service) { 'Media Data Service' }

          let(:deploy) { Deploy.create image: image, user: user, account: account_id }
          let(:entry) { Entry.create(id: id, fields: fields) }
          let(:other_entry) { Entry.create(id: other_id, fields: other_fields) }
          let(:fields) { Fields.create_from_data(data: { id: id, guid: guid, ref: other_id }) }
          let(:other_fields) { Fields.create_from_data(data: { id: other_id, guid: guid }) }
          let(:image) { Image.create(account_id: account_id, user: user, entries: Entries.create(collection: [entry, other_entry]), state: :untransformed) }
          let(:user) { User.create username: 'a_dev@example.org', password: 'b', token: 'token' }

          before do
            allow(Entry).to receive(:new).and_return(entry, other_entry)
            entry.id = entry.fields['id']
            other_entry.id = other_entry.fields['id']
          end

          it { is_expected.to be_a_kind_of Creatable }

          describe "Attributes" do
            it { is_expected.to have_attributes(image: nil) }
            it { is_expected.to have_attributes(user: nil) }
            it { is_expected.to have_attributes(account: nil) }
            it { is_expected.to have_attributes(post_block: nil) }
            it { is_expected.to have_attributes(pre_block: nil) }
          end

          describe "Instance method signatures" do
            it { is_expected.to respond_to(:block_update_entry).with(2).argument.and_unlimited_arguments }
            it { is_expected.to respond_to(:dependencies).with(0).arguments }
            it { is_expected.to respond_to(:deploy).with(1..2).arguments }
            it { is_expected.to respond_to(:deploy_order).with(0).arguments }
          end

          describe "#dependencies" do
            let(:result) { deploy.dependencies }

            it { expect(result).to be_a Hash }

            context "when the image has no entries" do
              let(:fields) { Fields.create_from_data(data: { id: id, guid: guid }) }

              it "is expected to be an empty hash" do
                expect(deploy.dependencies).to eq({})
              end
            end

            context "when the image has a key with no dependencies in the value" do
              let(:fields) { Fields.create_from_data(data: { id: id, guid: guid }) }

              it "is expected to be an empty hash" do
                expect(result).to eq({})
              end
            end

            context "when the image has a key with dependencies in the value" do
              it "is expected to return an array with dependencies" do
                expect(result).to eq("http://data.media.theplatform.com/data/Media/1"=>["http://data.task.theplatform.com/data/Task/1"])
              end
            end
          end

          describe "#deploy_order" do
            # before { deploy.image.entries.first.fields['ref'] = "http://data.task.theplatform.com/task/data/Task/1" }

            it "is expected to return an array of references in deployable order" do
              expect(deploy.deploy_order).to eq [other_id, id]
            end

            context "when the deploy state is :transformed" do
              it "is expected to return nil" do
                image.instance_variable_set :@state, :transformed
                expect(deploy.deploy_order).to eq nil
              end
            end

            context "when an image is not deployable" do
              before { image.entries.remove other_entry }

              it "is expected to return nil" do
                expect(deploy.deploy_order).to eq nil
              end
            end
          end

          describe "#block_update_entry" do
            let(:block) { proc { |entry| entry } }

            it "is expected to duplicate the original entry" do
              expect(deploy.block_update_entry(entry, &block)).not_to be entry
            end

            it "is expected to yield the block with entry and args" do
              expect { |b| deploy.block_update_entry(entry, &b) }.to yield_with_args(a_kind_of(entry.class), [])
            end

            it "is expected to return an entry" do
              expect(deploy.block_update_entry(entry, &block)).to be_a_kind_of Entry
            end

            context "when the first argument is not a type of entry" do
              it "is expected to raise an argument error" do
                expect { deploy.block_update_entry(nil, &block) }.to raise_error ArgumentError, /argument must be an entry/
              end
            end
          end

          describe "#deploy" do
            let(:block) { proc { |entry| entry } }
            let(:args) { ['argu', 'ments', 1, 2, { a: 'a' }] }
            let(:query) { Query.new }
            let(:response) { Driver::Response.new }
            let(:page) { Driver::Page.create entries: [{ id: id, guid: guid }] }
            let(:guid) { 'carpe_diem' }
            let(:id) { 'http://data.media.theplatform.com/data/Media/1' }

            before do
              deploy.image.entries.first.fields.remove 'ref'
              allow(entry).to receive(:exists_by?).and_return(true)
              image.entries.each { |e| allow(e).to receive(:save) { e.id = Parameters.media_entry['id'].tr('1', '2') } }
              allow(other_entry).to receive(:exists_by?).and_return(true)
              allow(Query).to receive(:new).and_return query
              allow(query).to receive(:run).and_return(response)
              allow(response).to receive(:status).and_return(200)
              allow(response).to receive(:page).and_return(page)
              allow(Aci.logger).to receive(:info).and_return nil
            end

            it "is expected to call log.info with the the guid, and the id" do
              deploy.deploy account_id
              expect(Aci.logger).to have_received(:info).with(/.*#{entry.fields['guid']}.*#{entry.id.tr '1', '2'}.*/).twice
            end

            it { expect(deploy.deploy(account_id)).to eq true }

            # TODO: move the deploy.deploy bit to the before when you fix the deploy_order destruction bug.
            it do
              deploy.deploy account_id
              expect(image.entries).to all(have_received(:save).with(user: a_kind_of(User)))
            end

            it "is expected to use entry.exists_by? to see if the entry exists." do
              deploy.deploy account_id
              expect(entry).to have_received(:exists_by?)
            end

            it "is expected to change the entry ownerId to the target account" do
              expect { deploy.deploy account_id }.to change { entry.fields['ownerId'] }.to account_id
            end

            context "when the entry exists" do
              let(:other_entry_id) { "http://data.media.theplatform.com/media/data/Media/2" }

              it "is expected to set id to the existing entry id" do
                expect { deploy.deploy account_id }.to change { entry.fields['id'] }.to other_entry_id
              end

              it "is expected to set ownerId to the existing entry ownerId" do
                expect { deploy.deploy account_id }.to change { entry.fields['ownerId'] }.to account_id
              end

              it "is expected to call puts with a PUT in the message" do
                deploy.deploy account_id
                expect(Aci.logger).to have_received(:info).with(a_string_including('PUT')).twice
              end
            end

            context "when the entry does not exist" do
              before do
                allow(entry).to receive(:exists_by?).and_return(false)
                allow(entry).to receive(:save).and_return(true)
              end

              it "is expected to set the id to nil" do
                expect { deploy.deploy account_id }.to change(entry, :id).to nil
              end

              it "is expected to call puts with a POST in the message" do
                deploy.deploy account_id
                expect(Aci.logger).to have_received(:info).with(a_string_including('POST'))
              end
            end

            context "when Validator.image_deployable? returns false" do
              before { allow(Validators).to receive(:image_deployable?).and_return(false) }

              it { expect { deploy.deploy account_id }.to raise_error RuntimeError, /not a deployable image/ }
            end

            context "when deploy.pre_block is set" do
              before { deploy.pre_block = block }

              it "is expected to call block_update_entry with entry, extra args, and pre_block" do
                allow(deploy).to receive(:block_update_entry).and_return(deploy.image.entries.first)
                deploy.deploy(account_id, *args)
                expect(deploy).to have_received(:block_update_entry).with(deploy.image.entries.first, *args, &deploy.pre_block)
              end

              # rubocop: disable RSpec/MultipleExpectations
              # reason: ordered exceptions to assure pre_block is called before save.
              it "is expected to be called before the entry is saved." do
                allow(deploy).to receive(:block_update_entry).and_return(deploy.image.entries.first)
                deploy.deploy(account_id, *args)
                expect(deploy).to have_received(:block_update_entry).with(deploy.image.entries.first, *args, &deploy.pre_block).ordered
                expect(deploy.image.entries.first).to have_received(:save).twice.ordered
              end
              # rubocop: enable RSpec/MultipleExpectations
            end

            context "when deploy.post_block is set" do
              before { deploy.post_block = block }

              it "is expected to call block_update_entry with entry, extra args, and post_block" do
                allow(deploy).to receive(:block_update_entry).and_return(deploy.image.entries.first)
                deploy.deploy(account_id, *args)
                expect(deploy).to have_received(:block_update_entry).with(deploy.image.entries.first, *args, &deploy.post_block)
              end

              # rubocop: disable RSpec/MultipleExpectations
              # reason: ordered exceptions to assure pre_block is called before save.
              it "is expected to be called after the entry is saved" do
                allow(deploy).to receive(:block_update_entry).and_return(deploy.image.entries.first)
                deploy.deploy(account_id, *args)
                expect(deploy.image.entries.first).to have_received(:save).ordered
                expect(deploy).to have_received(:block_update_entry).with(deploy.image.entries.first, *args, &deploy.post_block).ordered
              end
              # rubocop: enable RSpec/MultipleExpectations
            end
          end
        end
      end
    end
  end
end
