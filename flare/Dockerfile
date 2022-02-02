# build go proxy from source
FROM golang:1.16 AS builder_source
ARG GO_PROXY_GITHUB_USER=apache
ARG GO_PROXY_GITHUB_BRANCH=master
RUN git clone --branch ${GO_PROXY_GITHUB_BRANCH} \
   https://github.com/${GO_PROXY_GITHUB_USER}/openwhisk-runtime-go /src ;\
   cd /src ; env GO111MODULE=on CGO_ENABLED=0 go build main/proxy.go && \
   mv proxy /bin/proxy

# or build it from a release
FROM golang:1.16 AS builder_release
ARG GO_PROXY_RELEASE_VERSION=1.16@1.18.0
RUN curl -sL \
  https://github.com/apache/openwhisk-runtime-go/archive/{$GO_PROXY_RELEASE_VERSION}.tar.gz\
  | tar xzf -\
  && cd openwhisk-runtime-go-*/main\
  && GO111MODULE=on go build -o /bin/proxy

#FROM python:3.9-buster
FROM rocker/tidyverse:4.1.2
ARG DEBIAN_FRONTEND=noninteractive

# Install Python
ARG BUILDDIR="/tmp/build"
ARG PYTHON_VER="3.9.0"
WORKDIR ${BUILDDIR}

RUN wget --quiet https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz > /dev/null 2>&1 && \
tar zxf Python-${PYTHON_VER}.tgz && \
cd Python-${PYTHON_VER} && \
./configure  > /dev/null 2>&1 && \
make > /dev/null 2>&1 && \
make install > /dev/null 2>&1 && \
rm -rf ${BUILDDIR}

# select the builder to use
ARG GO_PROXY_BUILD_FROM=release

# Install common modules for python
COPY requirements_common.txt requirements_common.txt
COPY requirements.txt requirements.txt
RUN pip3 install --upgrade pip six wheel &&\
    pip3 install --no-cache-dir -r requirements.txt

RUN mkdir -p /action
WORKDIR /

COPY --from=builder_source /bin/proxy /bin/proxy_source
COPY --from=builder_release /bin/proxy /bin/proxy_release
RUN mv /bin/proxy_${GO_PROXY_BUILD_FROM} /bin/proxy

ADD bin/compile /bin/compile
ADD lib/launcher.py /lib/launcher.py

# log initialization errors
ENV OW_LOG_INIT_ERROR=1
# the launcher must wait for an ack
ENV OW_WAIT_FOR_ACK=1
# using the runtime name to identify the execution environment
ENV OW_EXECUTION_ENV=openwhisk/action-python-v3.9
# compiler script
ENV OW_COMPILER=/bin/compile

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install apt-utils \
  	vim \
  	curl \
  	libgdal-dev \
  	libnetcdf-dev \
  	libudunits2-0 \
  	libjq-dev \
  	libxt6 \
  	make \
  	zlib1g-dev && \
    R -e "install.packages(c('yaml', 'remotes', 'imputeTS', 'rMR', 'here', 'aws.s3', 'libxt6'), repos = 'https://cloud.r-project.org')" && \
    R -e "remotes::install_github('FLARE-forecast/Rnoaa4cast@7e401340b004910ff328dec7d4ec6ef0cbcc6863')" && \
    R -e "remotes::install_github('FLARE-forecast/GLM3r@768cdef2bcd2b04feec912eeacb175d67ff88598')" && \
    R -e "remotes::install_github('vahid-dan/FLAREr@f336759db35a55081313a9b4a4d51b36a1e8fdc3')"

# Copy Files to Container
COPY source.sh /root/
COPY flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

# Start Container
#WORKDIR /root/
#CMD "./flare-run-container.sh"
ENTRYPOINT ["/bin/proxy"]
