# Deploy

## Create

```ruby
server_deploy = Cts::Mpx::Aci::Tasks::Deploy.create account: target_account, user: target_account_user, image: server_image
```

## Deploy

```ruby
server_deploy.deploy target_account
```

## Deploy dependencies

```ruby
server_deploy.dependencies
```

## Deploy order

```ruby
server_deploy.deploy_order
```
