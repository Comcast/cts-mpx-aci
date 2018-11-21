# Collect

## Create

```ruby
media_entries = Cts::Mpx::Aci::Tasks::Collect.create(
  user:    user,
  account: account,
  queries: [{
    "service"  => "Media Data Service",
    "endpoint" => "media",
    "fields"   => ['id', 'guid']
  }]
)
```

## Run

```ruby
media_entries.collect
```
