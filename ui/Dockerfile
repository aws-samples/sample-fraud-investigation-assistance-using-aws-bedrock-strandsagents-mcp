#checkov:skip=CKV_DOCKER_3:Container for local testing for so non-root user not required
#checkov:skip=CKV_DOCKER_2:Container for local testing for so health checks not required
FROM python:3.12-slim@sha256:e55523f127124e5edc03ba201e3dbbc85172a2ec40d8651ac752364b23dfd733

# remember to expose the port your app'll be exposed on.
EXPOSE 8080

RUN pip install -U --no-cache-dir pip

COPY requirements.txt app/requirements.txt
RUN pip install --no-cache-dir -r app/requirements.txt

# copy into a directory of its own (so it isn't in the toplevel dir)
COPY . /app
WORKDIR /app

# run it!
ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8080", "--server.address=0.0.0.0"]
