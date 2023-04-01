# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Updated nostrum to 0.6.1.
- Updated all other dependencies.

### Fixed

- Name of the example application in the `Nosedrum.ApplicationCommand`
  supervisor example.


## v0.4.0 - 27.11.2021

### Added

- Application command support, via the `Nosedrum.ApplicationCommand` behaviour,
  as well as the `Nosedrum.Interactor` behaviour & the
  `Nosedrum.Interactor.Dispatcher` implementation.
- First-class alias support for traditional commands. If you implemented your
  own `Nosedrum.Storage`, then you will need to update it to incorporate this
  change. See [the diff for
  `Nosedrum.Storage.ETS`](https://github.com/jchristgit/nosedrum/commit/9debfa61fe787078ea2f2337dae9833a9608b477#diff-a464efb4145969295c7ab63ec6b50f734c2b3f45e32f12e5050eaeb4aea4679a)
  as an example of nosedrum implemented it.

### Changed

- Cache entire messages in message cache implementations.
- Return direct values from `:ets.insert` or `Agent.get_and_update` in
  `Nosedrum.MessageCache` implementations. If you match on the `:ok` value
  returned in `MessageCache.get` or `MessageCache.update`, you will need to
  update your code.
- Change value to signal "return all cached messages" in
  `Nosedrum.MessageCache.recent_in_guild` from `nil` to `:infinity`.


## v0.3.0 - 7.12.2020

### Added
- Support for nested subcommands. Command paths now need to be passed as a list
  instead of a tuple. This may also require an update to custom invokers, see
  changes to `Nosedrum.Invoker.Split` for details.

### Fixed
- Prevent compiler warning about `@short_version` module attribute.

### Changed
- Return error tuples instead of creating error messages in the API.
  Specifically, this means that for the following events, manual error checking
  needs to be performed:
  - Unknown subcommands - these return `{:error, {:unknown_subcommand, name,
    :known, known_subcommands}}` from the invoker.
  - Predicate permission check failures or error - these return `{:error,
    :predicate, predicate_result}` from the invoker.


## 0.2.1 - 11.02.2019
### Changed
- Use hex version of Nostrum.


## 0.2.0 - 10.02.2019
### Added
- The `Nosedrum.Predicates` module, which includes the `has_permission/1`
  and `guild_only/1` predicates and performs predicate evaluation in command
  invokers.
- The `Nosedrum.MessageCache` behaviour, along with two implementations,
  `Nosedrum.MessageCache.Agent` and `Nosedrum.MessageCache.ETS`.
- `Nosedrum.Helpers.quoted_split/1`.
- `Nosedrum.Storage.ETS` now supports the `:tid` call which returns the internal
  ETS table identifier.

### Changed
- Command predicates are now evaluated lazily. This means that you can create
  predicates which depend on previous predicates to evaluate as `:passthrough`,
  for example, a permission predicate might want a `guild_only` predicate used
  before.
- `Nosedrum.Storage` was updated to allow implementations to take a `reference`
  that identifies which storage you want to access. In the case of
  `Nosedrum.Storage.ETS`, you can use this to pass the ETS table reference.
- `Nosedrum.Invoker` now supports passing the storage process reference (or ETS
  table name in case of `Nosedrum.Storage.ETS` for `handle_message`.


## 0.1.0 - 03.02.2019
Initial release.

<!-- vim: set textwidth=80 ts=2 sw=2: -->
