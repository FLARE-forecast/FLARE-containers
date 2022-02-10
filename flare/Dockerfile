ARG DEBIAN_FRONTEND=noninteractive

# Build go proxy from a Release
FROM golang:1.16 AS builder_release
ARG GO_PROXY_RELEASE_VERSION=1.16@1.18.0
RUN curl -sL \
    https://github.com/apache/openwhisk-runtime-go/archive/{$GO_PROXY_RELEASE_VERSION}.tar.gz\
    | tar xzf -\
    && cd openwhisk-runtime-go-*/main\
    && GO111MODULE=on go build -o /bin/proxy

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
    apt-get -yqq install apt-utils=2.0.6 \
  	vim=2:8.1.2269-1ubuntu5.7 \
  	curl=7.68.0-1ubuntu2.7 \
  	libgdal-dev=3.0.4+dfsg-1build3 \
  	libnetcdf-dev=1:4.7.3-1 \
  	libudunits2-0=2.2.26-5 \
  	libjq-dev=1.6-1ubuntu0.20.04.1 \
  	libxt6=1:1.1.5-1 \
  	make=4.2.1-1.2 \
  	zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.2 \
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
    R -e "remotes::install_github('FLARE-forecast/FLAREr@2b616044447c61857def7b133e53af96bca54bc2')"

#Install common modules for python
COPY requirements.txt requirements.txt
RUN pip install --upgrade pip six wheel &&\
    pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /action
WORKDIR /

COPY --from=builder_release /bin/proxy /bin/proxy_release
RUN mv /bin/proxy_release /bin/proxy

ADD bin/compile /bin/compile
ADD lib/launcher.py /lib/launcher.py

#log initialization errors
ENV OW_LOG_INIT_ERROR=1
#the launcher must wait for an ack
ENV OW_WAIT_FOR_ACK=1
#using the runtime name to identify the execution environment
ENV OW_EXECUTION_ENV=openwhisk/action-python-v3.9
#compiler script
ENV OW_COMPILER=/bin/compile

# Copy Files to Container
COPY source.sh /root/
COPY flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

# Start Container
#CMD "./flare-run-container.sh"
ENTRYPOINT ["/bin/proxy"]
