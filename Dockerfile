FROM ghcr.io/smkwlab/texlive-ja-textlint:2026e@sha256:e2d935e5042b599b5359121459ecf232540a982b13d56429e4da2b663dffc550

# Keep this base image tag in sync with latex-environment's devcontainer
# (.devcontainer/devcontainer.json). Renovate (shared smkwlab/.github:latex
# preset) tracks new texlive-ja-textlint releases.

# Install GitHub CLI and jq
#
# jq reads the pull request's head commit out of the event payload so the
# release tag can point at it (#77). The base image carries neither -- node
# is there, but a JSON parser that is not the document toolchain's runtime is
# the clearer dependency to declare.
# Note: On GitHub Actions (amd64), texlive-ja-textlint:2026e uses Alpine Linux base
# Alpine package cleanup is omitted because:
# - This container is ephemeral (created and destroyed per GitHub Actions job)
# - Cleanup only affects image size, not runtime performance
# - Simpler code is preferred for maintainability
RUN apk add --no-cache github-cli jq

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
