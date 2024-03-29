ARG DEBIAN_FRONTEND=noninteractive

FROM rocker/tidyverse:4.2

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install --no-install-recommends --yes apt-utils=2.0.9 \
    vim=2:8.1.2269-1ubuntu5.7 \
    curl=7.68.0-1ubuntu2.11 \
    libgdal-dev=3.0.4+dfsg-1build3 \
    libnetcdf-dev=1:4.7.3-1 \
    libudunits2-0=2.2.26-5 \
    libjq-dev=1.6-1ubuntu0.20.04.1 \
    libxt6=1:1.1.5-1 \
    zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.3 \
    jq=1.6-1ubuntu0.20.04.1 \
    libcbor0.6=0.6.0-0ubuntu1 \
    libfido2-1=1.3.1-1ubuntu2 \
    libxmuu1=2:1.1.3-0ubuntu1 \
    openssh-client=1:8.2p1-4ubuntu0.5 \
    xauth=1:1.1-0ubuntu1 \
    libzmq5=4.3.2-2ubuntu1 \
    python3=3.8.2-0ubuntu2 \
    python3-pip=20.0.2-5ubuntu1.6 && \
    rm -rf /var/lib/apt/lists/* && \
    R -e "devtools::install_version('yaml', version = '2.3.5', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('remotes', version = '2.4.2', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('imputeTS', version = '3.2', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('rMR', version = '1.1.0', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('here', version = '1.0.1', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('aws.s3', version = '0.3.21', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('googlesheets4', version = '1.0.0', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('gsheet', version = '0.4.5', repos = 'https://cloud.r-project.org')" && \
    R -e "remotes::install_github('FLARE-forecast/Rnoaa4cast@faa3a329d8c1ccec0f40ce847b6750f9a22b3ba8')" && \
    R -e "remotes::install_github('FLARE-forecast/GLM3r@768cdef2bcd2b04feec912eeacb175d67ff88598')" && \
    R -e "remotes::install_github('FLARE-forecast/FLAREr@1ac3e0cfa9c573922cb105402d04f65b78000d1d')"

# Upgrade and Install Basic Python Dependencies
RUN update-ca-certificates \
    && pip install --upgrade pip setuptools six \
    && pip install --no-cache-dir gevent==21.12.0 flask==2.1.2

ENV FLASK_PROXY_PORT 8080

RUN mkdir -p /actionProxy/owplatform
ADD flare/actionproxy.py /actionProxy/
ADD flare/owplatform/__init__.py /actionProxy/owplatform/
ADD flare/owplatform/knative.py /actionProxy/owplatform/
ADD flare/owplatform/openwhisk.py /actionProxy/owplatform/

RUN mkdir -p /action
ADD flare/stub.sh /action/exec
RUN chmod +x /action/exec

# Copy Files
ADD flare/VERSION .
COPY commons/source.sh /root/
COPY flare/flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

CMD R -e "devtools::package_info(pkgs = c('FLAREr', 'GLM3r', 'Rnoaa4cast'), include_base = FALSE, dependencies = FALSE)" && cd actionProxy && python3 -u actionproxy.py
