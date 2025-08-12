# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
FROM python:3.13-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends git nodejs npm curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv
RUN uv tool install git+https://github.com/sparfenyuk/mcp-proxy

ENV PATH="/root/.local/bin:$PATH"

# Expose the server port
EXPOSE 8080

CMD ["mcp-proxy", "--host=0.0.0.0", "--pass-environment", "--port=8080", "npx", "@modelcontextprotocol/server-brave-search"]