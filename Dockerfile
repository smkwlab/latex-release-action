FROM ghcr.io/smkwlab/texlive-ja-textlint:2025i

# Install GitHub CLI
# Note: apt-get clean and cache cleanup are omitted because:
# - This container is ephemeral (created and destroyed per GitHub Actions job)
# - Cleanup only affects image size, not runtime performance
# - The base image (texlive-ja-textlint:2025i) is already 544MB
# - gh CLI adds minimal size (~20MB), cleanup saves only a few MB
# - Simpler code is preferred for maintainability
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
