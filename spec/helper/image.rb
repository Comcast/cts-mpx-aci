module Cts
  module Mpx
    module Spec
      module Parameters
        module_function

        def image
          {
            "account"     => "http://access.auth.theplatform.com/data/Account/1",
            "collections" => collections
          }
        end

        def undeployable_image
          {
            "account"     => "http://access.auth.theplatform.com/data/Account/1",
            "collections" => collections
          }
        end

        # collection with same entry by guid but different variables otherwise
        def differential_image
          h = image
          h['collections']['Media Data Service'].first.id += '3'
          h
        end

        # image containing the same entries as image, but with an additional entry
        def added_image
          h = image
          entry = Create.entry
          entry["guid"] = 'new_guid'
          h['collections']['Media Data Service'].push entry
          h
        end

        # image containing the same entries as image, but with one entry missing.
        def missing_image
          h = image
          h['collections']['Media Data Service'].entries.last.guid = 'new_guid'
          h
        end
      end
    end
  end
end
