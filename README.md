# LaTeX Release Action
GitHub Action to build LaTeX documents and create GitHub Releases.

## Features
- Builds LaTeX documents using latexmk
- Creates GitHub Release with the compiled PDFs
- Supports multiple LaTeX files in a single build
- Supports both pull request builds and tag-based releases
- Uses TeXLive environment with Japanese support

## Usage
Create a workflow file (e.g., `.github/workflows/latex-build.yml`):
```yaml
name: Build and Release PDF
on:
  pull_request_target:
  push:
    tags:
      - '*'
permissions:
  contents: write
jobs:
  document:
    runs-on: ubuntu-latest
    container: ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine
    steps:
      - uses: smkwlab/latex-release-action@v2
        with:
          files: document, presentation
```

### Inputs

| Name | Description | Required |
|------|-------------|----------|
| `files` | Comma-separated list of LaTeX file names without `.tex` extension<br>Example: `main, appendix, presentation` | Yes |

### Behavior

- On pull requests:
  - Builds the LaTeX documents
  - Creates a pre-release with tag `{branch-name}-release`

- On tag push:
  - Builds the LaTeX documents
  - Creates a release with tag `{tag-name}-release`

## Migration from v1

The action has been updated to support multiple files in v2. To migrate from v1:

- Update the action version from `@v1` to `@v2`
- Change the input parameter from `file: document` to `files: document`
- To build multiple files, use comma-separated values: `files: document, presentation`

## Requirements

- The LaTeX files must be in the repository root
- Requires a Docker container with `latexmk` capability
  - Example: `ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine`
- Requires `contents: write` permission for creating releases

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors
- Maintained by [Shimokawa Laboratory](https://github.com/smkwlab)
