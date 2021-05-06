FROM rocker/tidyverse:4.0.4

# Set Environment Variables
ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/user/bin:${PATH}"

# Setup FLARE User
RUN groupadd --gid 5000 user \
    && useradd --home-dir /home/user --create-home --uid 5000 \
        --gid 5000 --shell /bin/sh --skel /dev/null user \
    && mkdir -p /home/user/bin /home/user/flare/shared \
    && chown -R user:user /home/user \
    && chmod -R 777 /home/user/flare/shared

WORKDIR /home/user

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
        jq

RUN su - user -c "wget -O /home/user/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /home/user/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc"

# Install Node
ENV NODE_VERSION=14.16.1
RUN su - user -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash"
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
RUN su - user -c "mkdir -p /home/user/flare/"
COPY --chown=user:user flare-download-observations/flare-container.sh /home/user/flare
COPY --chown=user:user commons/commons.sh /home/user/flare
RUN su - user -c "chmod +x /home/user/bin/yq /home/user/bin/mc /home/user/flare/flare-container.sh"

# Start OpenWhisk Service
WORKDIR /code
COPY --chown=user:user flare-download-observations/. /code
EXPOSE 8080
USER user
CMD ["npm", "start"]
