FROM ghcr.io/smkwlab/texlive-ja-textlint:2026e@sha256:e2d935e5042b599b5359121459ecf232540a982b13d56429e4da2b663dffc550

# Keep this base image tag in sync with latex-environment's devcontainer
# (.devcontainer/devcontainer.json). Renovate (shared smkwlab/.github:latex
# preset) tracks new texlive-ja-textlint releases.

# Install GitHub CLI
# Note: On GitHub Actions (amd64), texlive-ja-textlint:2026e uses Alpine Linux base
# Alpine package cleanup is omitted because:
# - This container is ephemeral (created and destroyed per GitHub Actions job)
# - Cleanup only affects image size, not runtime performance
# - Simpler code is preferred for maintainability
RUN apk add --no-cache github-cli

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
