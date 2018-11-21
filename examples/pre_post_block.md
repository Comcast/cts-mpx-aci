# Pre and Post block example.

```ruby
#!/usr/bin/env ruby
require 'cts/mpx/aci'
require 'ruby-progressbar'
require 'pry'

include Cts::Mpx::Aci::Tasks

username = 'mpx/test-user@theplatform.com'
account = 'http://access.auth.theplatform.com/data/Account/2694754993'
record_account = 'http://access.auth.theplatform.com/data/Account/2694756913'
deploy_account = 'http://access.auth.theplatform.com/data/Account/2694756913'

user = Theplatform::Services::User.new username, Theplatform::Credentials[username]
user.account = record_account
user.sign_in

deploy_user = Theplatform::Services::User.new username, Theplatform::Credentials[username]
deploy_user.account = deploy_account
deploy_user.sign_in

# All the data that represents our feature.

feature = Collect.create user: user, account: record_account, queries: [
  {
    'service'  => 'Media Data Service',
    'endpoint' => 'Media',
    'fields'   => ['id', 'guid', 'title', 'ownerId', 'eb$trailerUrl']
  }, {
    'service'  => 'Media Data Service',
    'endpoint' => 'MediaFile',
    'fields'   => ['id', 'guid', 'title', 'originalUrl', 'mediaId', 'ownerId']
  }, {
    'service'  => 'Media Data Service',
    'endpoint' => 'MediaField',
    'fields'   => ['id', 'guid', 'title', 'ownerId', 'fieldName', 'namespace']
  }, {
    'service'  => 'Media Data Service',
    'endpoint' => 'Category',
    'fields'   => ['id', 'guid', 'title', 'ownerId']
  }, {
    'service'  => 'Media Data Service',
    'endpoint' => 'AssetType',
    'fields'   => ['id', 'guid', 'title', 'ownerId']
  }
]

feature.collect

feature_image = Cts::Mpx::Aci::Tasks::Image.create(
  user:        user,
  account:     record_account,
  collections: feature.collections
)

### Make everything abstract and save
feature_image.transform
feature_image.save_to_directory 'feature-trailers'

# binding.pry  # uncomment this to break here with feature_image complete and saved.

### Deploy

deploy_image = Image.load_from_directory 'feature-trailers'

feature_deploy = Cts::Mpx::Aci::Tasks::Deploy.create account: deploy_account, user: deploy_user, image: deploy_image

feature_deploy.pre_block = proc do |entry|
  print "Attempting to deploy a #{entry.endpoint} named #{entry.guid} . . . "
  entry
end

feature_deploy.post_block = proc do |entry, args|
  puts "successful."
  args[0].increment
  if entry.endpoint == 'Media'
    print "#{entry.guid} is a media, calling fms to generate mediaFile . . . "

    output = Theplatform::Services::Web::FileManagementService::FileManagement.linkNewFile(
      user,
      'mediaId'       => entry.id,
      'sourceUrl'     => entry.eb_trailerUrl,
      'mediaFileInfo' => { 'guid' => "#{entry.guid}-1080p" }
    )

    puts "#{output["fileId"]}."
  end
end


feature_deploy.image.user = deploy_user
feature_deploy.image.untransform deploy_account

progressbar = ProgressBar.create total: feature_deploy.image.entries.count

feature_deploy.deploy deploy_account, progressbar

# binding.pry # uncomment this to interact with the feature_deploy object.
```
