# carla-common

Minimal Docker container that can be used for developing Python code using CARLA 0.9.13 Python API.

Run it like this:
```sh
COMMIT=$(git rev-parse --short HEAD) USER_ID=$(id -u) GROUP_ID=$(id -g) docker-compose -f docker-compose.yml up -d --build
```

The default `docker-compose.yml` only runs the container with the client. If you also want a server, you can use the `server/docker-compose.yml` and `.env` files like this:

```sh
COMMIT=$(git rev-parse --short HEAD) USER_ID=$(id -u) GROUP_ID=$(id -g) docker-compose -f docker-compose.yml -f server/docker-compose.yml --env-file .env up -d --build
```

`.env` file contains server config variables.

In your code you can then use `server` when specifying the CARLA server hostname in `carla.Client`.

## Writing your own Dockerfile

```Dockerfile
ARG PLATFORM=nvidia
FROM wielgoszinfo/carla-common:${PLATFORM}-latest AS base

ENV PACKAGE=your-package-name

# anything you need here, e.g.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    nano \
    && rm -rf /var/lib/apt/lists/*
USER ${USERNAME}

RUN /venv/bin/python -m pip install --no-cache-dir \
    numpy==1.22.1
# ...

# Copy client files so that we can do editable pip install
COPY --chown=${USERNAME}:${USERNAME} . /app

# Please do not set the WORKDIR (it is set to /home/carla by default)
# or overwrite the ENTRYPOINT so it can find entrypoint.sh if needed (it is set to [ "./entrypoint.sh" ] by default)
```