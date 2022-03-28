# nvidia or cpu
ARG PLATFORM=nvidia

# ----------------------------------------------------------------------------
# Choose base image based on the ${PLATFORM} variable
# ----------------------------------------------------------------------------

FROM nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04 as base-nvidia
FROM ubuntu:20.04 as base-cpu
FROM base-${PLATFORM} as base

# ----------------------------------------------------------------------------
# Common dependencies
# ----------------------------------------------------------------------------

ENV TZ=Europe/Warsaw
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    ffmpeg \
    g++ \
    gcc \
    git \
    libboost-python-dev \
    libjpeg-dev \
    libjpeg-turbo8-dev \
    libpng-dev \
    python3-pip \
    python3-venv \
    screen \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=carla
ENV USERNAME=${USERNAME}
ENV HOME /home/${USERNAME}

RUN groupadd -g ${GROUP_ID} ${USERNAME} \
    && useradd -ms /bin/bash -u ${USER_ID} -g ${GROUP_ID} ${USERNAME} \
    && echo "${USERNAME}:${USERNAME}" | chpasswd \
    && mkdir ${HOME}/.vscode-server ${HOME}/.vscode-server-insiders /outputs /venv /app \
    && chown ${USERNAME}:${USERNAME} ${HOME}/.vscode-server ${HOME}/.vscode-server-insiders /outputs /venv /app

# Everything else can be run as user since we need venv anyway
USER ${USERNAME}

# Create venv to allow editable installation of python packages
RUN python3 -m venv /venv

# Update basic python packages
RUN /venv/bin/python -m pip install --no-cache-dir -U \
    pip==21.3.1 \
    setuptools==59.5.0 \
    wheel==0.37.1

# Add some utility/development requirements
RUN /venv/bin/python -m pip install --no-cache-dir \
    autopep8 \
    ipython \
    ipykernel \
    ipywidgets \
    pylint \
    pytest \
    pytest-cov \
    unify

# Automatically activate virtualenv for user
RUN echo 'source /venv/bin/activate' >> ${HOME}/.bashrc

# Install carla client library
RUN /venv/bin/python -m pip install --no-cache-dir \
    carla==0.9.13

# Copy the 'agents' package used by e.g. scenario runner. It is a part of provided PythonAPI, but not a part of carla package.
COPY --from=carlasim/carla:0.9.13 --chown=${USERNAME}:${USERNAME} /home/carla/PythonAPI/carla/agents /venv/lib/python3.8/site-packages/agents

COPY --chown=${USERNAME}:${USERNAME} ./entrypoint.sh ${HOME}/entrypoint.sh

WORKDIR ${HOME}
ENTRYPOINT [ "./entrypoint.sh" ]

# Run infinite loop to allow easily attach to container
CMD ["/bin/sh", "-c", "while sleep 1000; do :; done"]

# Those you probably want to map to host/named volumes
VOLUME [ "/outputs", "${HOME}/.vscode-server", "${HOME}/.vscode-server-insiders" ]

# It may also be beneficial to map /app to a host directory with your code