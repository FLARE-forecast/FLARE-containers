FROM rocker/tidyverse:4.1.2

# Set Environment Variables
#ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive

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

# Install Python
ARG BUILDDIR="/tmp/build"
ARG PYTHON_VER="3.10.2"
WORKDIR ${BUILDDIR}

RUN wget --quiet https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz > /dev/null 2>&1 && \
tar zxf Python-${PYTHON_VER}.tgz && \
cd Python-${PYTHON_VER} && \
./configure  > /dev/null 2>&1 && \
make > /dev/null 2>&1 && \
make install > /dev/null 2>&1 && \
rm -rf ${BUILDDIR} 

# Copy Files to Container
COPY source.sh /root/
COPY flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

# Start Container
WORKDIR /root/
CMD "./flare-run-container.sh"
