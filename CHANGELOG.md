# Changelog

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

