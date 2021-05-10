FROM python:3

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

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install jq && \
    wget -O /home/user/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /home/user/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && \
    pip3 install pycurl certifi PyYAML

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
RUN mkdir -p /home/user/flare/scripts/
COPY --chown=user:user flare-download-noaa/flare-container.sh /home/user/flare/
COPY --chown=user:user commons/commons.sh /home/user/flare/
RUN chown -R user:user /home/user/bin/yq /home/user/bin/mc /home/user/flare/ && \
    chmod +x /home/user/bin/yq /home/user/bin/mc /home/user/flare/flare-container.sh
COPY --chown=user:user flare-download-noaa/scripts/qdownloader.py /home/user/flare/scripts

# Start OpenWhisk Service
WORKDIR /openwhisk
COPY --chown=user:user flare-download-noaa/. /openwhisk
COPY --chown=user:user commons/flare_pullworkdir.sh /openwhisk
COPY --chown=user:user commons/flare_pushworkdir.sh /openwhisk
COPY --chown=user:user commons/flare_triggernext.sh /openwhisk
EXPOSE 8080
USER user:user
CMD ["npm", "start"]
