module Cts
  module Mpx
    module Spec
      module Parameters
        module_function

        def account
          "http://access.auth.theplatform.com/data/Account/1"
        end

        def reference
          "http://data.media.theplatform.com/media/data/Media/1"
        end

        def transformed_reference
          "urn:cts:aci:Media+Data+Service:Media:1:media_abcd"
        end

        def field_reference
          Parameters.media_field_entry["id"]
        end

        def transformed_field_reference
          "urn:cts:aci:Media+Data+Service:MediaField:1:http://www.comcast.com$a_custom_field"
        end

        def stencil
          {
            'name'    => 'test stencil',
            'queries' => [
              {
                "service":  "Media Data Service",
                "endpoint": "Server",
                "fields":   ["id", "guid", "title", "description", "ownerId"],
                "ids":      [1, 2, 3],
                "sort":     ['SORT'],
                "by":       { one: 1 },
                "other":    { one: 1 },
                "range":    1..500
              }
            ]
          }
        end
      end
    end
  end
end
