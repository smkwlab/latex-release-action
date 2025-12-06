#!/bin/bash
set -e

# Fix git safe.directory issue in Docker container
git config --global --add safe.directory /github/workspace

# Cleanup function for temporary directories
cleanup_temp_dir() {
  if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}

# Set trap to cleanup on exit
trap cleanup_temp_dir EXIT

# Get inputs from environment variables
INPUT_LATEX_OPTIONS="${INPUT_LATEX_OPTIONS:--interaction=nonstopmode}"
INPUT_CLEANUP="${INPUT_CLEANUP:-true}"
INPUT_PARALLEL="${INPUT_PARALLEL:-false}"

# Check if PR has .tex file changes (skip build if no .tex changes)
if [[ -n "${GITHUB_HEAD_REF}" ]]; then
  echo "::group::Checking for .tex changes in PR"
  echo "PR source branch: ${GITHUB_HEAD_REF}"

  # Set GitHub CLI authentication
  export GH_TOKEN="${GITHUB_TOKEN:-$GH_TOKEN}"

  if [[ -z "$GH_TOKEN" ]]; then
    echo "::warning::GITHUB_TOKEN not available. Cannot check PR changes. Proceeding with build."
    echo "::endgroup::"
  else
    # Extract PR number from GITHUB_REF if in merge context, otherwise use head branch
    if [[ "${GITHUB_REF}" =~ refs/pull/([0-9]+)/merge ]]; then
      PR_NUMBER="${BASH_REMATCH[1]}"
      echo "PR number: ${PR_NUMBER}"
      CHANGED_FILES=$(gh pr view "${PR_NUMBER}" --json files --jq '.files[].path' 2>/dev/null || echo "")
    else
      CHANGED_FILES=$(gh pr view "${GITHUB_HEAD_REF}" --json files --jq '.files[].path' 2>/dev/null || echo "")
    fi

    if [[ -z "$CHANGED_FILES" ]]; then
      echo "::warning::Could not retrieve PR changed files. Proceeding with build."
      echo "::endgroup::"
    else
      echo "Changed files in PR:"
      echo "$CHANGED_FILES" | sed 's/^/  /'

      # Check if any .tex files are in the changed files
      CHANGED_TEX_FILES=$(echo "$CHANGED_FILES" | grep -E '\.tex$' || true)

      if [[ -z "$CHANGED_TEX_FILES" ]]; then
        echo ""
        echo "::notice::No .tex files changed in this PR. Skipping build and release."
        echo "::endgroup::"
        # Set empty outputs for workflows that depend on them
        echo "pdf_files=" >> "$GITHUB_OUTPUT"
        echo "all_exist=true" >> "$GITHUB_OUTPUT"
        echo "processed_files=" >> "$GITHUB_OUTPUT"
        exit 0
      else
        echo ""
        echo "Found .tex changes:"
        echo "$CHANGED_TEX_FILES" | sed 's/^/  /'
      fi
      echo "::endgroup::"
    fi
  fi
fi

echo "::group::Preparing file list"
echo "Input files: ${INPUT_FILES}"

# Convert comma-separated list to array and trim whitespace
IFS=',' read -ra TEX_FILES <<< "${INPUT_FILES}"

# Check file existence and build list of existing files only
FILES_TO_CHECK=""
PROCESSED_FILES=""
SKIPPED_FILES=""

for file in "${TEX_FILES[@]}"; do
  file=$(echo $file | xargs)  # trim whitespace
  if [[ -z "$file" ]]; then
    echo "::warning::Empty file name found in input, skipping"
    continue
  fi

  # Sanitize file name (remove potentially dangerous characters)
  # Note: Dot (.) is allowed for file extensions and paths like "dir.name/file"
  # Hyphen is placed at the end of character class to avoid range interpretation
  if [[ ! "$file" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
    echo "::error::Invalid file name: $file (only alphanumeric, underscore, hyphen, dot, and slash allowed)"
    exit 1
  fi

  # Check if the .tex file exists
  if [[ -f "$file.tex" ]]; then
    FILES_TO_CHECK+="$file.tex,"
    PROCESSED_FILES+="$file,"
    echo "✓ Found file: $file.tex"
  else
    SKIPPED_FILES+="$file.tex,"
    echo "⚠ Skipping missing file: $file.tex"
  fi
done

FILES_TO_CHECK=${FILES_TO_CHECK%,}  # remove trailing comma
PROCESSED_FILES=${PROCESSED_FILES%,}  # remove trailing comma
SKIPPED_FILES=${SKIPPED_FILES%,}  # remove trailing comma

if [[ -z "$FILES_TO_CHECK" ]]; then
  echo "::warning::No valid LaTeX files found to build. All specified files are missing:"
  if [[ -n "$SKIPPED_FILES" ]]; then
    echo "Missing files: $SKIPPED_FILES"
  fi
  echo "::endgroup::"
  exit 0
fi

echo "Files to build: $FILES_TO_CHECK"
if [[ -n "$SKIPPED_FILES" ]]; then
  echo "Skipped files: $SKIPPED_FILES"
fi
echo "::endgroup::"

# Build PDF files by latexmk
echo "::group::Building LaTeX files"
echo "LaTeX options: ${INPUT_LATEX_OPTIONS}"
echo "Parallel build: ${INPUT_PARALLEL}"

IFS=',' read -ra TEX_FILES <<< "${PROCESSED_FILES}"
BUILD_FAILED=false

if [[ "${INPUT_PARALLEL}" == "true" ]]; then
  echo "Building files in parallel..."
  pids=()
  TEMP_DIR=$(mktemp -d) || {
    echo "::error::Failed to create temporary directory"
    exit 1
  }
  echo "Using temporary directory: $TEMP_DIR"

  for file in "${TEX_FILES[@]}"; do
    file=$(echo $file | xargs)
    # Sanitize filename for use in temp file names
    safe_name=$(echo "$file" | tr '/' '_')
    echo "Starting build for: $file.tex"
    (
      # Note: exit 1 here only exits the subshell, not the main script
      # The main script waits for all processes and checks exit codes below
      if latexmk -cd ${INPUT_LATEX_OPTIONS} "$file.tex" 2>&1; then
        echo "0" > "$TEMP_DIR/exit_$safe_name"
        echo "✓ Successfully built $file.tex"
      else
        echo "1" > "$TEMP_DIR/exit_$safe_name"
        echo "::error::Failed to build $file.tex"
        exit 1
      fi
    ) &
    pids+=($!)
  done

  # Wait for all builds to complete and collect results
  overall_success=true
  for i in "${!pids[@]}"; do
    pid=${pids[$i]}
    file=$(echo "${TEX_FILES[$i]}" | xargs)
    safe_name=$(echo "$file" | tr '/' '_')

    if wait $pid; then
      echo "Process for $file.tex completed successfully"
    else
      echo "Process for $file.tex failed"
      overall_success=false
    fi

    # Double-check with exit code file for redundancy
    # Note: This warning appears when the subshell exits unexpectedly before writing the file
    # The `wait $pid` above already caught the failure, so this is a safety check
    if [[ -f "$TEMP_DIR/exit_$safe_name" ]]; then
      exit_code=$(cat "$TEMP_DIR/exit_$safe_name")
      if [[ "$exit_code" != "0" ]]; then
        echo "::error::Build failed for $file.tex (exit code: $exit_code)"
        overall_success=false
      fi
    else
      echo "::warning::No exit code file found for $file.tex"
      overall_success=false
    fi
  done

  # Cleanup temporary directory is handled by trap

  if [[ "$overall_success" != "true" ]]; then
    BUILD_FAILED=true
  fi
else
  echo "Building files sequentially..."
  for file in "${TEX_FILES[@]}"; do
    file=$(echo $file | xargs)
    echo "Building: $file.tex"

    if ! latexmk -cd ${INPUT_LATEX_OPTIONS} "$file.tex"; then
      echo "::error::Failed to build $file.tex"
      echo "LaTeX build failed. Check the logs above for details."
      BUILD_FAILED=true
      break
    else
      echo "✓ Successfully built $file.tex"
    fi
  done
fi

if [[ "$BUILD_FAILED" == "true" ]]; then
  echo "::error::One or more LaTeX builds failed"
  exit 1
fi

echo "::endgroup::"

# Check PDF files and cleanup
echo "::group::Checking PDF files and cleanup"
IFS=',' read -ra TEX_FILES <<< "${PROCESSED_FILES}"
ALL_EXIST=true
PDF_FILES=""

for file in "${TEX_FILES[@]}"; do
  file=$(echo $file | xargs)
  if [ ! -f "$file.pdf" ]; then
    echo "::error::PDF file not found: $file.pdf"
    ALL_EXIST=false
  else
    echo "✓ Found PDF: $file.pdf"
    PDF_FILES+="$file.pdf,"
  fi
done

PDF_FILES=${PDF_FILES%,}

# Cleanup intermediate files if requested
if [[ "${INPUT_CLEANUP}" == "true" ]]; then
  echo "Cleaning up intermediate files..."
  for file in "${TEX_FILES[@]}"; do
    file=$(echo $file | xargs)
    # Remove common LaTeX intermediate files
    rm -f "$file.aux" "$file.log" "$file.fls" "$file.fdb_latexmk" \
          "$file.synctex.gz" "$file.out" "$file.toc" "$file.lot" \
          "$file.lof" "$file.bbl" "$file.blg" "$file.idx" \
          "$file.ind" "$file.ilg" "$file.nav" "$file.snm" \
          "$file.vrb" "$file.figlist" "$file.makefile" \
          "$file.figlist.makefile" "$file.figlist.fls" \
          "$file.figlist.fdb_latexmk"
  done
  echo "Cleanup completed"
else
  echo "Skipping cleanup (cleanup=false)"
fi

echo "::endgroup::"

# Set outputs
echo "pdf_files=${PDF_FILES}" >> "$GITHUB_OUTPUT"
echo "all_exist=${ALL_EXIST}" >> "$GITHUB_OUTPUT"
echo "processed_files=${PROCESSED_FILES}" >> "$GITHUB_OUTPUT"

if [[ "$ALL_EXIST" != "true" ]]; then
  exit 1
fi

# Create a release if all PDFs exist
echo "::group::Creating GitHub Release"

# Get release name from input
INPUT_RELEASE_NAME="${INPUT_RELEASE_NAME:-}"

# Determine release tag and name based on context
if [[ -n "${GITHUB_HEAD_REF}" ]]; then
  # Pull request context
  TAG_NAME="${GITHUB_HEAD_REF}-release"
  RELEASE_NAME="${INPUT_RELEASE_NAME:-${GITHUB_HEAD_REF} Release}"
  IS_PRERELEASE="true"
elif [[ "${GITHUB_REF}" == refs/tags/* ]]; then
  # Tag push context
  TAG_NAME="${GITHUB_REF#refs/tags/}"
  RELEASE_NAME="${INPUT_RELEASE_NAME:-${TAG_NAME} Release}"
  IS_PRERELEASE="false"
elif [[ "${GITHUB_REF}" == refs/heads/* ]]; then
  # Branch push context
  BRANCH_NAME="${GITHUB_REF#refs/heads/}"
  TAG_NAME="${BRANCH_NAME}-release"
  RELEASE_NAME="${INPUT_RELEASE_NAME:-${BRANCH_NAME} Release}"
  IS_PRERELEASE="true"
else
  # Fallback to run number
  TAG_NAME="release-${GITHUB_RUN_NUMBER}"
  RELEASE_NAME="${INPUT_RELEASE_NAME:-Release ${GITHUB_RUN_NUMBER}}"
  IS_PRERELEASE="true"
fi

echo "Tag name: ${TAG_NAME}"
echo "Release name: ${RELEASE_NAME}"
echo "Is prerelease: ${IS_PRERELEASE}"

# Convert PDF_FILES to array
IFS=',' read -ra PDF_ARRAY <<< "${PDF_FILES}"

# Delete existing release if exists (to allow re-creation with updated assets)
echo "Checking for existing release with tag: ${TAG_NAME}"
if gh release view "${TAG_NAME}" &>/dev/null; then
  echo "Deleting existing release: ${TAG_NAME}"
  gh release delete "${TAG_NAME}" --yes --cleanup-tag || {
    echo "::warning::Failed to delete existing release"
  }
  # Explicitly delete the tag to avoid race condition with --cleanup-tag
  # The GitHub API may not complete tag deletion before gh release create runs
  echo "Ensuring tag is deleted: ${TAG_NAME}"
  gh api -X DELETE "repos/${GITHUB_REPOSITORY}/git/refs/tags/${TAG_NAME}" 2>/dev/null || true
  # Small delay to ensure API propagation
  sleep 1
fi

# Create release using GitHub CLI with auto-generated notes
if [[ "${IS_PRERELEASE}" == "true" ]]; then
  gh release create "${TAG_NAME}" \
    --title "${RELEASE_NAME}" \
    --generate-notes \
    --prerelease \
    "${PDF_ARRAY[@]}" || {
      echo "::error::Failed to create release"
      echo "::error::This may happen if there are permission issues"
      exit 1
    }
else
  # For non-prerelease, omit --prerelease flag
  # Note: By default, gh CLI marks releases as latest unless --prerelease is specified
  # We don't specify --latest to allow GitHub's automatic latest detection
  gh release create "${TAG_NAME}" \
    --title "${RELEASE_NAME}" \
    --generate-notes \
    "${PDF_ARRAY[@]}" || {
      echo "::error::Failed to create release"
      echo "::error::This may happen if there are permission issues"
      exit 1
    }
fi

echo "::endgroup::"
