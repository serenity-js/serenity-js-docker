FROM ubuntu:noble@sha256:e96e81f410a9f9cae717e6cdd88cc2a499700ff0bb5061876ad24377fcc517d7

LABEL org.opencontainers.image.source="https://github.com/serenity-js/serenity-js-docker"
LABEL org.opencontainers.image.description="Serenity/JS runtime environment: Ubuntu, Node.js, JRE, Playwright browsers, Google Chrome, Microsoft Edge"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ARG USERNAME=serenity-js
ARG USER_UID=1001
ARG USER_GID=1001

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright

## OS Layer

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
### Install certificate tools
    apt-get install -y ca-certificates curl gpg libnss3-tools p11-kit && \
    update-ca-certificates && \
### Update sources
    mkdir -p /etc/apt/keyrings && \
    curl -sL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" >> /etc/apt/sources.list.d/nodesource.list && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list && \
    curl -sL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get -y update && \
### Install Node.js
    apt-get install -y default-jre google-chrome-stable microsoft-edge-stable nodejs rsync sudo && \
### Feature-parity with node.js base images.
    apt-get install -y --no-install-recommends git openssh-client && \
### Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*;

## Application Layer

COPY playwright-installer /tmp/playwright-installer/

RUN \
### Install Playwright
    mkdir "$PLAYWRIGHT_BROWSERS_PATH" && \
    cd /tmp/playwright-installer/ && \
    npm ci  && \
    npm exec --no -- playwright install --with-deps && \
    cd - && \
    chmod -R 755 "$PLAYWRIGHT_BROWSERS_PATH"  && \
### Clean up
    rm -rf /tmp/* && \
    npm cache clean --force > /dev/null 2>&1 && \
    rm -rf "$HOME/.npm/" && \
### Add user
    addgroup --gid "$USER_GID" "$USERNAME" && \
    adduser --disabled-password --gecos "" --uid "$USER_UID" --ingroup "$USERNAME" "$USERNAME" && \
### Configure sudo for the user
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
### Set permissions
    chown -R "$USERNAME":"$USERNAME" "$PLAYWRIGHT_BROWSERS_PATH";

USER $USERNAME
WORKDIR /home/$USERNAME
