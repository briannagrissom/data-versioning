# Use the official Debian-hosted Python image
FROM python:3.11-slim-bookworm

# Ensure we're running as root for the build
USER root

ARG DEBIAN_PACKAGES="build-essential git curl wget unzip gzip"

# Prevent apt from showing prompts
ENV DEBIAN_FRONTEND=noninteractive

# Python wants UTF-8 locale
ENV LANG=C.UTF-8

# Tell pipenv where the shell is. This allows us to use "pipenv shell" as a
# container entry point.
ENV PYENV_SHELL=/bin/bash

# Tell Python to disable buffering so we don't lose any logs.
ENV PYTHONUNBUFFERED=1

# Tell uv to copy packages from the wheel into the site-packages
ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT=/.venv

RUN set -ex && \
    for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends $DEBIAN_PACKAGES && \
    apt-get install -y lsb-release && \
    apt-get install -y --no-install-recommends software-properties-common apt-transport-https ca-certificates gnupg2 gnupg-agent curl openssh-client

RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt gcsfuse-bookworm main" > /etc/apt/sources.list.d/gcsfuse.list && \
    apt-get update && \
    apt-get install -y gcsfuse google-cloud-sdk

RUN apt-get install -y libnss3 libcurl4 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip && \
    pip install uv

RUN id -u app &>/dev/null || useradd -ms /bin/bash app -d /home/app -u 1000

RUN mkdir -p /app && \
    chown app:app /app && \
    mkdir -p /.venv && \
    chown app:app /.venv

RUN mkdir -p /mnt/gcs_data && chown app:app /mnt/gcs_data


# Switch to the new user
#USER app # Keep the user as root since we need for mounting
WORKDIR /app

# Copy dependency files first for better layer caching
COPY --chown=app:app pyproject.toml uv.lock* ./

# Install dependencies in a separate layer for better caching
RUN uv sync --frozen

# Copy the rest of the source code
COPY --chown=app:app . ./

# Entry point
#ENTRYPOINT ["pipenv","shell"]
ENTRYPOINT ["/bin/bash","./docker-entrypoint.sh"]