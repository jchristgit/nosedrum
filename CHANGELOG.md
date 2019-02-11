# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Changed


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
