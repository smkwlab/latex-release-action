# LaTeX Release Action

GitHub Action to build LaTeX documents and create GitHub Releases.

## Features

- Builds LaTeX documents using latexmk
- Creates GitHub Release with the compiled PDF
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
      - uses: smkwlab/latex-release-action@v1
        with:
          file: document
```

### Inputs

- `file`: LaTeX file name without `.tex` extension (required)

### Behavior

- On pull requests:
  - Builds the LaTeX document
  - Creates a pre-release with tag `{branch-name}-release`

- On tag push:
  - Builds the LaTeX document
  - Creates a release with tag `{tag-name}-release`

## Requirements

- The LaTeX file must be in the repository root
- Uses `ghcr.io/smkwlab/texlive-ja-textlint:2023c-alpine` container
- Requires `contents: write` permission for creating releases

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- Maintained by [Shimokawa Laboratory](https://github.com/smkwlab)
