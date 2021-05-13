FROM rocker/tidyverse:4.0.5

# Set Environment Variables
ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/user/bin:${PATH}"

# Setup FLARE User
RUN groupadd --gid 5000 user \
    && useradd --home-dir /home/user --create-home --uid 5000 \
        --gid 5000 --shell /bin/sh --skel /dev/null user

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
    R -e "remotes::install_github('eco4cast/EFIstandards@bf5aff16c04052fe50c14f61eace358f9550925d')" && \
    R -e "remotes::install_github('FLARE-forecast/FLAREr@368da65c3df396570c71b8072fe3fcb5ab0ea9fa')"

# Install Node
ENV NODE_VERSION=14.16.1
RUN su - user -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash"
ENV NVM_DIR=/home/user/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/home/user/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# Download Dependencies
USER user
RUN mkdir -p /home/user/bin/
RUN wget -O /home/user/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /home/user/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
RUN chmod +x /home/user/bin/yq /home/user/bin/mc

# Copy Files to Container
RUN mkdir -p /home/user/flare/
COPY --chown=user:user flare-visualize/flare-container.sh /home/user/flare/
COPY --chown=user:user commons/commons.sh /home/user/flare/
RUN chmod +x /home/user/flare/flare-container.sh
ADD --chown=user:user flare-visualize/flare_lake_examples/ /home/user/flare/flare_lake_examples/

# Start OpenWhisk Service
RUN mkdir /home/user/openwhisk/
WORKDIR /home/user/openwhisk/
RUN npm install && \
    npm install shelljs \
        nodemon \
        express
RUN mv /home/user/openwhisk/node_modules /home/user/node_modules
COPY --chown=user:user flare-visualize/. /home/user/openwhisk/
COPY --chown=user:user commons/flare_pullworkdir.sh /home/user/openwhisk/
COPY --chown=user:user commons/flare_pushworkdir.sh /home/user/openwhisk/
COPY --chown=user:user commons/flare_triggernext.sh /home/user/openwhisk/
EXPOSE 8080
CMD ["npm", "start"]
