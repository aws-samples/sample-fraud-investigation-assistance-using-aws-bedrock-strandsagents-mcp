
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#checkov:skip=CKV_DOCKER_3:Prototype/development environment - non-root user not required for prototype
#checkov:skip=CKV_DOCKER_2:Health checks implemented at ECS level
FROM python:3.13-slim-bullseye

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir uv && \
    uv tool install git+https://github.com/sparfenyuk/mcp-proxy

ENV PATH="/root/.local/bin:$PATH"

# Expose the server port
EXPOSE 8080

CMD ["mcp-proxy", "--host=0.0.0.0", "--port=8080", "uvx", "mcp-server-fetch"]