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
	libnode-dev \
	libxt6 && \
    R -e "install.packages(c('yaml', 'remotes', 'imputeTS', 'rMR', 'here', 'aws.s3', 'libxt6'), repos = 'https://cloud.r-project.org')" && \
    R -e "remotes::install_github('FLARE-forecast/Rnoaa4cast@7e401340b004910ff328dec7d4ec6ef0cbcc6863')" && \
    R -e "remotes::install_github('FLARE-forecast/GLM3r@768cdef2bcd2b04feec912eeacb175d67ff88598')" && \
    R -e "remotes::install_github('vahid-dan/FLAREr@f336759db35a55081313a9b4a4d51b36a1e8fdc3')"

# Install Node
#ENV NODE_VERSION=16.13.2
#RUN apt install -y curl
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
#ENV NVM_DIR=/root/.nvm
#RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
#RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
#RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
#ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
#RUN node --version
#RUN npm --version

# Copy Files to Container
COPY source.sh /root/
COPY flare-run-container.sh /root/
RUN chmod +x /root/source.sh /root/flare-run-container.sh

# Start Container
WORKDIR /root/
CMD "./flare-run-container.sh"
