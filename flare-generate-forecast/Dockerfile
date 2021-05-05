FROM rocker/tidyverse:4.0.4

# Set Environment Variables
ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install wget \
        git \
        libxml2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        ssh \
        tzdata \
        vim \
        curl \
        libnetcdf-dev \
        libjq-dev \
        libudunits2-dev \
        libnode-dev \
        libgd-dev \
        jq && \
    R -e "install.packages(c('yaml', 'remotes', 'imputeTS', 'rMR', 'stinepack'), repos = 'https://cloud.r-project.org')" && \
    R -e "remotes::install_github('FLARE-forecast/noaaGEFSpoint@fc08f6272da5b7bdeec3b764050e490482d27240')" && \
    R -e "remotes::install_github('eco4cast/EFIstandards@085bcd5e39b6ffb0ef94ce1fa692ed5810ea6ae3')" && \
    R -e "remotes::install_github('FLARE-forecast/FLAREr@eac9c0a5c6201495d1978ab3415f2fc51d14d34a')" && \
    wget -O /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /usr/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
# Install Node
ENV NODE_VERSION=14.16.1
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash
ENV NVM_DIR=/home/user/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/home/user/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm install && \
    npm install shelljs \
        nodemon \
        express

# Copy Files to Container
RUN mkdir -p /home/user/flare/flare_lake_examples/
COPY flare-container.sh /home/user/flare/
RUN wget -O /home/user/flare/commons.sh https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/21.01.4/commons/commons.sh
RUN chmod +x /usr/bin/yq /usr/bin/mc /home/user/flare/flare-container.sh
ADD flare_lake_examples/ /home/user/flare/flare_lake_examples/

# Start OpenWhisk Service
WORKDIR /code
COPY . /code
EXPOSE 8080
CMD ["npm", "start"]
