# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Also I copied this intro verbatim from [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [v0.5.0 - 2023-07-04]
### Changed
* Switch to go port of `thcon` (i.e. call `thcon listen` instead of `thcon-listen`)
* Support lua nvim configs more gracefully

## [v0.4.0 - 2021-03-24]
### Added
* New `thcon#load()` function that loads previously-applied settings

### Changed
* BREAKING CHANGE: Removed support for `.let`, `.set`, `.setglobal` and `.colorscheme` in remote payload, in favor of re-`:source`ing the file at `.rc_file`.  Requires thcon@0.9.0.

## [v0.3.0 - 2021-02-25]
### Changed
* Replaced thcon-vim.sh script (previously packaged with this plugin) with `thcon-listen` (packaged with `thcon` 0.7.0 and above)
