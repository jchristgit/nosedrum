# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- The `Nosedrum.Predicates` module, which includes the `has_permission/1`
  predicate and performs predicate evaluation in command invokers.

### Changed
- Command predicates are now evaluated lazily. This means that you can create
  predicates which depend on previous predicates to evaluate as `:passthrough`,
  for example, a permission predicate might want a `guild_only` predicate used
  before.

## 0.1.0 - 03.02.2019
Initial release.

<!-- vim: set textwidth=80 ts=2 sw=2: -->
