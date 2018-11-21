# Cts::Mpx::Aci

The ACI (Account Continuous Integration) toolkit allows you to record, image, and deploy Video Platform data services entries to or from mpx accounts.

## Installation

### From GHE

Clone the repo to a local directory:

    git clone https://github.comcast.com/thePlatform/cts-mpx-aci

Build the gem:

    cd cts-mpx-aci
    rake build

Install the gem:

    gem install pkg/*.gem

### From a gem repo

Make sure its source exists in your gem sources.

To add a source to the gem command:

    gem source -a https://ctsgems.corp.theplatform.com

Once that is done:

    gem install cts-mpx-aci

## Requirements

Add the following libraries to your program to use ACI.

- `require 'cts/mpx/aci'`

## Usage

The ACI toolkit is made up of a series of tasks in the form of Ruby classes and modules.

Some familiarity with the Ruby SDK is expected. You will need to understand how to make a user and log in that user to work with the ACI.

Understanding how query, entries, and collection works will also help.

### Tasks

#### Collect

`Collect` runs a series of queries that can be used in memory or stored to disk in an image.

`User` is an SDK user and `account` is the numeric form of an account ID. This will not work with a account title.

`Queries` is an array of hashes. Each one can be any endpoint on any service. These will get passed into the SDK query class and executed. Any field that the data service shell takes will be passed in. There is no restriction on the amount of queries, services, or endpoints that can be included.

To create one:

```ruby
media_entries = Cts::Mpx::Aci::Tasks::Collect.create(
  user:    user,
  account: account,
  queries: [{
    "service"  => "Media Data Service",
    "endpoint" => "Media",
    "fields"   => "id,guid"
  }]
)
```

Once it's created you can execute the `collect` method and it will fetch the results and store them in a `collection` attribute.

#### Image

`Image` generates an image from series of collections. Images can be stored and loaded from disk and are created in a format suitable for use with a SCM.

To create one:

```ruby
media_image = Cts::Mpx::Aci::Tasks::Image.create(
  user:    user,
  account: account,
  entries: account_collection.entries
)
```

You can supply any hash of collections as long as the service name is the key. Most times this will be supplied by the collect task.

This task supplies several methods that allow you to `transform`, `untransform`, `save_to_disk` and `load_from_disk`.

##### Load from directory

Loading an image from a directory:

```ruby
media_image = Cts::Mpx::Aci::Tasks::Image.load_from_directory('directory/path')
```

##### Save to disk

Saving an image to a directory:

```ruby
image.save_to_directory('directory/path')
```

##### Transform

To transform an image to an abstract (transformed) state:

```ruby
image.transform
```

##### Untransform

To untransform an image from the directory you must assure the `user` is set correctly, and supply a target account:

```ruby
image.untransform 'http://access.auth.theplatform.com/data/Account/1'
```

##### Add or merge images

To merge the contents of two images together they must share a state, user, and account. To merge two images together you can use `image.merge`. The behavior of `merge` is identical to the `Hash#merge` method.

```ruby
new_image = image.merge other_image
```

The date taken attribute will be updated to the current time.

#### Deploy

`Deploy` will take the entries from an image and deploy them to a target account. The image must be in an untransformed state to do this.

To create a deploy:

```ruby
media_deploy = Cts::Mpx::Aci::Tasks::Deploy.create account: target_account, user: target_account_user, image: media_image
```

You must supply an existing, untransformed image for this to work.

To deploy an image:

```ruby
media_deploy.deploy target_account
```

### Helpers

#### Stencils

Stencils provide a mechanism to store a collection of queries together to be used repeatedly. They are stored in a JSON
format.

To create a stencil programatically:

* please refer to the sdk for more extensive usage examples of query.

```ruby
stencil = Cts::Mpx::Aci::Stencil.new
stencil.name = 'a test stencil'
stencil.queries = [{
                    "service":  "Media Data Service",
                    "endpoint": "Server",
                    "fields":     "id,guid,ownerId"
                  }]
```

To store a stencil in JSON format:

```JSON
{
  "name"    : "test stencil",
  "queries" : [
    {
      "service":  "Media Data Service",
      "endpoint": "Server",
      "fields":     "id,guid,ownerId"
    }
  ]
}
```

Once stored, you can load a file or a URL to get activate the stencil.

```ruby
Stencil.load_file "test_stencil.json"
```

```ruby
Stencil.load_url "https://github.comcast.com/cts/stencils/operations/servers.json"
```

The smart `load` method will attempt to load the stencil first as a string, then a URL, and finally as a file.

```ruby
Stencil.load "https://github.comcast.com/cts/stencils/operations/servers.json"
```

All stencils are cached in memory and subsequent loads will not reload them.

Once a stencil is loaded it is stored in `Stencil[]`. You can reference them by name with `Stencil['test stencil']` or see the entire array with `Stencil[]`.

#### Validators

A series of procedural tests that can assure your data is checked in a consistent manner.

#### Transformations

A collection of procedural functions that allow transformation of your data to and from an abstract format.

### How transformations work

At a high level, transforming an object to a non-account bound state requires you to analyze the entry for references you find to other services. You have to analyze the entire tree as well, being careful to walk both hashes and arrays correctly.

When you discover a reference, `Transformations.transform_reference` is called with a `user`, `reference`, and `original_account`. The user is the one doing the lookup, the reference is what's being transformed, and, critically, the original_account is the ownerId of the object.

For most objects transforming is straightforward: walk the object, find references, transform them. For account objects we do a special lookup to see if `reference` matches `original_account`. When it does, we set the value to the target-account token.

If the lookup cannot find the object, it will put the no-id token. Likewise, if the lookup does not receive a guid back, it will put the no-guid token.

Untransforming an object is effectively the same, in reverse. It splits the transformed reference into its smaller pieces, looks up the guid in the account, and, if able, will return the id of the related object.

If no id is found, either the user cannot read the object or the object does not exist in the account.
