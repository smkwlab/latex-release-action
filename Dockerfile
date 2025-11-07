FROM ghcr.io/smkwlab/texlive-ja-textlint:2025i

# Install GitHub CLI
# Note: On GitHub Actions (amd64), texlive-ja-textlint:2025i uses Alpine Linux base
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
