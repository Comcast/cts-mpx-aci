module Cts
  module Mpx
    module Spec
      module Parameters
        module_function

        def collections
          {
            "Media Data Service" => Create.collection(data: media_collection),
            "Task Data Service"  => Create.collection(data: task_collection)
          }
        end

        def collection
          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 1,
            "entryCount"   => 1,
            "entries"      => [media_entry]
          }
        end

        def media_collection
          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 1,
            "entryCount"   => 1,
            "entries"      => [untransformed_entry]
          }
        end

        def dual_media_collection
          media_entry2 = media_entry
          media_entry2['id'] = '2'
          media_entry2['guid'].reverse!

          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 2,
            "entryCount"   => 2,
            "entries"      => [media_entry, media_entry2]
          }
        end

        def task_collection
          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 1,
            "entryCount"   => 1,
            "entries"      => [task_entry]
          }
        end

        def server_collection
          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 1,
            "entryCount"   => 1,
            "entries"      => [server_entry]
          }
        end

        def dual_task_collection
          task_entry2 = task_entry
          task_entry2['id'] = '2'
          task_entry2['guid'].reverse!

          {
            "$xmlns"       => nil,
            "startIndex"   => 1,
            "itemsPerPage" => 2,
            "entryCount"   => 2,
            "entries"      => [task_entry, task_entry2]
          }
        end
      end
    end
  end
end
