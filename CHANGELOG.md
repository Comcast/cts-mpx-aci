# CHANGELOG

## 1.5.0

- Updated CompareImage for bug fixes
- Added json reporting to CompareImage

## 1.4.0

- split up and moved examples into their own directory.
- enhanced Validators.image_deployable? for either a string or symbol.
- Fixed Entry.save_to_service returning a group, not the entry after a POST
- moved the spec helpers out into it's own gem, now depends on it.
- added support to deploy to deploy mediafiles.
- added pre_block and post_block proc support to deploy.

## 1.3.5

- fixed two bugs preventing customFields from deploying.

## 1.3.4

- various fixes too README.md and EXAMPLES.md
- Updated Rakefile for end to end support of building and releasing for pages and the gem.
- Typo / example fixes in readme.
- Support for CTS Teamcity
- Added customfield support to deploy

## 1.3.3

- Updated Rakefile for end to end support of building and releasing for pages and the gem.

## 1.3.2

- fixed collection code so it properly stores multiple queries.
- fixed watchfolder recording.
- fixed image 'info' method when user is not set.
- aci will no longer attempt to transform feed pids.
- Added a logger, logging deploy and collect for now.

## 1.3.1

- bug fixes in collect.collect and transformations.

## 1.3.0

- Bug fixes in transformation as well as some cleanup around method signatures.
- Github Pages are now buildable and can be pushed comcast GHE.
- added CustomField support to the transformations.

## 1.2.0

- bug fixes, coverage, rubocop updates.
- Extended the Stencil class to include new load methods and loaded stencils are available in memory.
- Format of the transformation id's changed from using `%20` to `+`

## 1.1.0

- Added Image.merge to merge two images together in memory.
- Added CompareImage class to support producing differentials between two images.
- Revamped all of the specs for cleaner methods and names.
- Built mocks, parameters, and simple creation methods for assiting in spec design.
- Added spec\_\* files for cleaner specs.
- Numerous bug fixes in transformations and deployment code.
