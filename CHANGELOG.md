# Changelog

## [v3.0.4] - 2025-11-07

### Fixed
- Fix git safe.directory error in Docker container (#37)

## [v3.0.3] - 2025-11-07

### Fixed
- Fix Docker Container Action env context error (#36)

## [v3.0.2] - 2025-11-07

### Fixed
- Fix GitHub token not being passed to Docker container (#34)

## [v3.0.1] - 2025-11-07

### Fixed
- Fix Alpine Linux compatibility for GitHub CLI installation (#33)

## [v3.0.0] - 2025-11-07

### Changed
- **BREAKING**: Convert from composite action to Docker container action (#32)
- Centralized TeXLive version management via container image

### Migration
- No workflow changes required for users
- Action now uses `ghcr.io/smkwlab/texlive-ja-textlint` container
- Improved isolation and consistency across environments

## [v2.5.0] - 2025-11-04

### Changed
- Remove permission fix step for root-based containers (#30)

## [v2.4.0] - 2025-11-04

### Fixed
- Fix permission handling for _runner_file_commands directory (#29)

## [v2.0.0] - 2025-02-15

### Added
- Support for building multiple LaTeX files in a single action
- New input parameter `files` that accepts comma-separated list of file names

### Changed
- **BREAKING**: Input parameter `file` renamed to `files`
- Release artifacts now include all successfully built PDFs

### Migration
- Update action version from `@v1` to `@v2`
- Change `file: document` to `files: document`
- To build multiple files, use: `files: document, presentation`

## [v1.0.0] - Initial Release

- Basic LaTeX document build support
- GitHub Release creation
- Support for pull request builds and tag-based releases

