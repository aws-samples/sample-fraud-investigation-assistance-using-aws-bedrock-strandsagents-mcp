# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#checkov:skip=CKV_DOCKER_3:Prototype/development environment - non-root user not required for prototype
#checkov:skip=CKV_DOCKER_2:Health checks implemented at ECS level
FROM python:3.13-slim-bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
COPY handler.py .
COPY README.md . 
COPY tools_description.py .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80 8080

CMD ["python", "handler.py"]