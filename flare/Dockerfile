ARG DEBIAN_FRONTEND=noninteractive

FROM rocker/tidyverse:4.1.2

# Install Python
# https://github.com/apache/openwhisk-runtime-python/blob/master/core/python39Action/Dockerfile
#ARG BUILDDIR="/tmp/build"
#ARG PYTHON_VER="3.9.0"
#WORKDIR ${BUILDDIR}

#RUN wget --quiet https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz > /dev/null 2>&1 && \
#tar zxf Python-${PYTHON_VER}.tgz && \
#cd Python-${PYTHON_VER} && \
#./configure  > /dev/null 2>&1 && \
#make > /dev/null 2>&1 && \
#make install > /dev/null 2>&1 && \
#rm -rf ${BUILDDIR}

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install --no-install-recommends --yes apt-utils=2.0.6 \
  	vim=2:8.1.2269-1ubuntu5.7 \
  	curl=7.68.0-1ubuntu2.7 \
  	libgdal-dev=3.0.4+dfsg-1build3 \
  	libnetcdf-dev=1:4.7.3-1 \
  	libudunits2-0=2.2.26-5 \
  	libjq-dev=1.6-1ubuntu0.20.04.1 \
  	libxt6=1:1.1.5-1 \
  	zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.2 \
    jq=1.6-1ubuntu0.20.04.1 \
    libcbor0.6=0.6.0-0ubuntu1 \
    libfido2-1=1.3.1-1ubuntu2 \
    libxmuu1=2:1.1.3-0ubuntu1 \
    openssh-client=1:8.2p1-4ubuntu0.4 \
    xauth=1:1.1-0ubuntu1 \
    python3=3.8.2-0ubuntu2 \
    python3-pip=20.0.2-5ubuntu1.6 && \
    rm -rf /var/lib/apt/lists/* && \
    R -e "devtools::install_version('yaml', version = '2.2.2', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('remotes', version = '2.4.2', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('imputeTS', version = '3.2', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('rMR', version = '1.1.0' , repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('here', version = '1.0.1', repos = 'https://cloud.r-project.org')" && \
    R -e "devtools::install_version('aws.s3', version = '0.3.21', repos = 'https://cloud.r-project.org')" && \
    R -e "remotes::install_github('FLARE-forecast/Rnoaa4cast@7e401340b004910ff328dec7d4ec6ef0cbcc6863')" && \
    R -e "remotes::install_github('FLARE-forecast/GLM3r@768cdef2bcd2b04feec912eeacb175d67ff88598')" && \
    R -e "remotes::install_github('FLARE-forecast/FLAREr@1ac3e0cfa9c573922cb105402d04f65b78000d1d')"

# Upgrade and Install Basic Python Dependencies
RUN update-ca-certificates \
    && pip install --upgrade pip setuptools six \
    && pip install --no-cache-dir gevent==21.12.0 flask==2.0.3

ENV FLASK_PROXY_PORT 8080

RUN mkdir -p /actionProxy/owplatform
ADD actionproxy.py /actionProxy/
ADD owplatform/__init__.py /actionProxy/owplatform/
ADD owplatform/knative.py /actionProxy/owplatform/
ADD owplatform/openwhisk.py /actionProxy/owplatform/

RUN mkdir -p /action
ADD stub.sh /action/exec
RUN chmod +x /action/exec

# Copy Files to Container
COPY source.sh /root/
COPY flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

CMD ["/bin/bash", "-c", "cd actionProxy && python3 -u actionproxy.py"]
