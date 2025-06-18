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

## MCP Tools Usage

### GitHub Operations
Use MCP tools instead of `gh` command for GitHub operations:
- **Development**: Use `mcp__gh-toshi__*` tools for development work
- **Student testing**: Use `mcp__gh-k19__*` tools only when testing student workflows

### Shell Command Gotchas

#### Backticks in gh pr create/edit
When using `gh pr create` or `gh pr edit` with `--body`, backticks (`) in the body text are interpreted as command substitution by the shell. This causes errors like:
```
permission denied: .devcontainer/devcontainer.json
command not found: 2025c-test
```

**Solution**: Always escape backticks with backslashes when using them in PR bodies:
```bash
# Wrong - will cause errors
gh pr create --body "Updated `file.txt` to version `1.2.3`"

# Correct - escaped backticks
gh pr create --body "Updated \`file.txt\` to version \`1.2.3\`"
```

## Security and Permission Guidelines

### 🚨 CRITICAL: GitHub Administration Rules

#### Git and GitHub Operations
- **NEVER use `--admin` flag** with `gh pr merge` or similar commands
- **NEVER bypass Branch Protection Rules** without explicit user permission
- **ALWAYS respect the configured workflow**: approval process, status checks, etc.

#### When Branch Protection Blocks Operations
1. **Report the situation** to user with specific error message
2. **Explain available options**:
   - Wait for required approvals
   - Wait for status checks to pass
   - Use `--auto` flag for automatic merge after requirements met
   - Request explicit permission for admin override (emergency only)
3. **Wait for user instruction** - never assume intent

#### Proper Error Handling Example
```bash
# When this fails:
gh pr merge 90 --squash --delete-branch
# Error: Pull request is not mergeable: the base branch policy prohibits the merge

# CORRECT response:
echo "Branch Protection Rules prevent merge. Options:"
echo "1. Wait for required approvals (currently need: 1)"
echo "2. Wait for status checks (currently pending: build-and-release-pdf)"
echo "3. Use --auto to merge automatically when requirements met"
echo "4. Request admin override (emergency only)"
echo "Please specify how to proceed."

# WRONG response:
gh pr merge 90 --squash --delete-branch --admin  # NEVER DO THIS
```

#### Emergency Admin Override
- Only use `--admin` flag when explicitly requested by user
- Document the reason for override in commit/PR description
- Report the action taken and why it was necessary

### Rationale
Branch Protection Rules exist to:
- Ensure code quality through required reviews
- Prevent accidental breaking changes
- Maintain audit trail of changes
- Enforce consistent development workflow

Bypassing these rules undermines repository security and development process integrity.