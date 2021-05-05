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
        jq && \
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

# Setup FLARE User
RUN groupadd --gid 5000 user \
    && useradd --home-dir /home/user --create-home --uid 5000 \
        --gid 5000 --shell /bin/sh --skel /dev/null user

# Copy Files to Container
RUN mkdir -p /home/user/flare/
COPY flare-container.sh /home/user/flare
RUN wget -O /home/user/flare/commons.sh https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/21.01.4/commons/commons.sh
RUN chmod +x /usr/bin/yq /usr/bin/mc /home/user/flare/flare-container.sh

# Start OpenWhisk Service
WORKDIR /code
COPY . /code
EXPOSE 8080
USER user
CMD ["npm", "start"]
