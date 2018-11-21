# Full example

```ruby
username = 'mpx/test-user@theplatform.com'
account = 'http://access.auth.theplatform.com/data/Account/2694754993'
target_account = 'http://access.auth.theplatform.com/data/Account/2694756913'

user = Theplatform::Services::User.new username, Theplatform::Credentials[username]
user.account = account
user.sign_in

target_account_user = Theplatform::Services::User.new username, Theplatform::Credentials[username]
target_account_user.account = target_account
target_account_user.sign_in

profile_entries = Cts::Mpx::Aci::Tasks::Collect.create(
  user:    user,
  account: account,
  queries: [{
    "service"  => "Publish Data Service",
    "endpoint" => "PublishProfile",
    "fields"   => ["id",
                   "guid",
                   "title",
                   "added",
                   "ownerId",
                   "locked",
                   "isCustom",
                   "disabled",
                   "fileTargets",
                   "fileTargetCount",
                   "publishProfileIds",
                   "outletProfileIds",
                   "autoPublishScript",
                   "disableAutoRevokes",
                   "disableAutoUpdates",
                   "supportingProfile",
                   "ownerId"]
  }]
)

profile_entries.collect

profile_image = Cts::Mpx::Aci::Tasks::Image.create(
  user:        user,
  account:     account,
  collections: profile_entries.collections
)

profile_deploy = Cts::Mpx::Aci::Tasks::Deploy.create account: target_account, user: target_account_user, image: profile_image
profile_deploy.deploy target_account
server_entries = Cts::Mpx::Aci::Tasks::Collect.create(
  user:    user,
  account: account,
  queries: [{
    "service"  => "Media Data Service",
    'endpoint' => 'Server',
    'fields'   => ["id",
                   "guid",
                   "title",
                   "description",
                   "ownerId",
                   "allowedAccountIds",
                   "failoverStreamingUrl",
                   "downloadUrl",
                   "formats",
                   "iconUrl",
                   "maximumFolderCount",
                   "organizeByOwner",
                   "organizeForVolume",
                   "password",
                   "privateKey",
                   "pullUrl",
                   "storageUrl",
                   "streamingUrl",
                   "userName",
                   "zones"]
  }]
)

server_entries.collect

server_image = Cts::Mpx::Aci::Tasks::Image.create(
  user:        user,
  account:     account,
  collections: server_entries.collections
)

server_image.user = target_account_user
server_image.transform
server_image.untransform target_account
server_deploy = Cts::Mpx::Aci::Tasks::Deploy.create account: target_account, user: target_account_user, image: server_image
server_deploy.dependencies
server_deploy.deploy target_account
```
