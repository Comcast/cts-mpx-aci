# Image

## Create

```ruby
media_image = Cts::Mpx::Aci::Tasks::Image.create(
  user:        user,
  account:     account,
  collections: media_entries.collections
)
```

## Load from directory

```ruby
Cts::Mpx::Aci::Tasks::Image.load_from_directory 'directory'
```

## Save to disk

```ruby
media_image.save_to_disk 'directory'
```

## Transform

```ruby
media_image.transform
```

## Untransform

```ruby
media_image.untransform target_account
```

## Merge

```ruby
account_staging = account_dev_a_image.merge account_dev_b_image
```
