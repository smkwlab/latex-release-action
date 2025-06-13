# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitHub Action for automating LaTeX document compilation and release creation. It builds LaTeX documents using `latexmk` and automatically creates GitHub releases with the compiled PDFs.

## Key Commands

### Testing
```bash
# Run all tests (recommended before commits)
./test.sh

# Run specific test suites
./test.sh logic    # Quick validation tests (no LaTeX required)
./test.sh local    # Test with local LaTeX installation
./test.sh docker   # Full integration test with Docker
./test.sh act      # Test GitHub Actions workflow with act
```

### Development
```bash
# Test LaTeX compilation locally
latexmk -pdf test/sample.tex
latexmk -pdf test/document2.tex

# Clean LaTeX artifacts
latexmk -C test/sample.tex
```

## Architecture

### Core Components
1. **action.yml**: Main GitHub Action definition
   - Input validation with regex patterns
   - File existence checking with smart skip logic
   - Sequential/parallel build orchestration
   - Release creation via softprops/action-gh-release

2. **test.sh**: Comprehensive test suite
   - Modular test sections (logic, local, docker, act)
   - Color-coded output for readability
   - Automatic cleanup of test artifacts

### Input Parameters
- `files`: Comma-separated list of LaTeX files (required)
- `latex_options`: Additional latexmk options (default: -pdf)
- `parallel`: Enable parallel compilation (default: false)
- `cleanup`: Remove intermediate files (default: true)
- `release_name`: Custom release name template

### Security Features
- Path traversal protection via regex validation
- Safe file handling with existence checks
- No arbitrary command execution
- Containerized execution environment

## Important Conventions

### File Handling (v2.0+)
- Missing files are gracefully skipped (not errors)
- At least one valid file must exist for successful execution
- Files outside repository are rejected for security

### Build Modes
- **Sequential**: Default mode, respects file dependencies
- **Parallel**: Faster for independent documents, use `parallel: true`

### Error Handling
- Missing files: Logged as warnings, build continues
- LaTeX errors: Full error output provided
- Invalid paths: Immediate failure with clear message

## Testing Guidelines

1. Always run `./test.sh logic` for quick validation
2. Use `./test.sh docker` for full integration testing
3. Check both single and multiple file scenarios
4. Verify error handling with missing files
5. Test both sequential and parallel builds

## Container Usage
Recommended container: `ghcr.io/smkwlab/texlive-ja-textlint:2025b`
- Full TeX Live installation
- Japanese language support
- Pre-built for performance
- Includes latexmk and dependencies