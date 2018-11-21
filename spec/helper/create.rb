module Cts
  module Mpx
    module Spec
      module Create
        module_function

        def user
          u = Theplatform::Services::User.new "a", "b"
          u.instance_variable_set('@token', 'test')

          # overrides the sign_out method since sdk calls at_exit
          u.define_singleton_method(:sign_out) {}
          u
        end

        def entry(user: nil, data: Parameters.media_entry)
          user ||= Create.user

          e = ::Theplatform::Services::Data::Entry.new data["id"]
          e.fields += data.keys
          data.each do |k, v|
            e.send "#{k}=", v
            e.user = user
          end
          e
        end

        def collection(user: nil, data: Parameters.dual_media_collection)
          user ||= Create.user

          c = Theplatform::Services::Data::Collection.new
          c.user = user

          data["entries"].each { |e| c.push Create.entry data: e }
          c
        end

        def image(user: nil, data: Parameters.image)
          user ||= Create.user

          Cts::Mpx::Aci::Tasks::Image.create user: user, account: data["account"], collections: data["collections"]
        end

        def stencil(data: Parameters.stencil)
          stencil = Cts::Mpx::Aci::Stencil.new

          stencil.name = data['name']
          stencil.queries = data['queries']
          # Cts::Mpx::Aci::Stencil.class_variable_set(:@@available_stencils, stencil.name =>stencil)
          stencil
        end
      end
    end
  end
end
