module Cts
  module Mpx
    module Spec
      module Parameters
        module_function

        def media_entry
          {
            "id"      => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
            "guid"    => 'media_abcd'
          }
        end

        def media_entry_no_guid
          {
            "id"      => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1"
          }
        end

        def media_field_entry
          {
            "id"        => "http://data.media.theplatform.com/media/data/MediaField/1",
            "ownerId"   => "http://access.auth.theplatform.com/data/Account/1",
            "guid"      => 'media_abcd',
            "namespace" => 'http://www.comcast.com',
            "fieldName" => 'a_custom_field'
          }
        end

        def server_entry
          {
            "id"      => "http://data.media.theplatform.com/media/data/Server/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
            "guid"    => 'media_abcd'
          }
        end

        def task_entry
          {
            "id"      => "http://data.task.theplatform.com/task/data/Task/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
            "guid"    => 'task_abcd'
          }
        end

        def untransformed_entry
          {
            "id"      => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
            "guid"    => 'media_abcd',
            "ref"     => "http://data.media.theplatform.com/media/data/Server/1"
          }
        end

        def transformed_entry
          {
            "id"      => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId" => "http://access.auth.theplatform.com/data/Account/1",
            "guid"    => 'media_abcd',
            "ref"     => 'urn:cts:aci:Media+Data+Service:Media:1:guid'
          }
        end

        def untransformed_entry_traversal
          {
            "id"                 => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId"            => "http://access.auth.theplatform.com/data/Account/1",
            "guid"               => 'media_abcd',
            "ref"                => "http://data.media.theplatform.com/media/data/Server/1",
            "ref_hash"           => { "ref" =>"http://data.media.theplatform.com/media/data/Server/1" },
            "ref_array"          => ["http://data.media.theplatform.com/media/data/Server/1", "http://data.media.theplatform.com/media/data/Server/1"],
            "ref_array_numerics" => [1, 2],
            "ref_array_hash"     => [{ "ref" => "http://data.media.theplatform.com/media/data/Server/1" }, { "ref" => "http://data.media.theplatform.com/media/data/Server/1" }]
          }
        end

        def transformed_entry_traversal
          {
            "id"             => "http://data.media.theplatform.com/media/data/Media/1",
            "ownerId"        => "http://access.auth.theplatform.com/data/Account/1",
            "guid"           => 'media_abcd',
            "ref"            => 'urn:cts:aci:Media+Data+Service:Media:1:guid',
            "ref_hash"       => { "ref" => "urn:cts:aci:Media+Data+Service:Media:1:guid" },
            "ref_array"      => ["not_a_ref", "urn:cts:aci:Media+Data+Service:Media:1:guid"],
            "ref_array_hash" => [{ "ref" => "urn:cts:aci:Media+Data+Service:Media:1:guid" }, { "ref" => "urn:cts:aci:Media+Data+Service:Media:1:guid" }]
          }
        end
      end
    end
  end
end
