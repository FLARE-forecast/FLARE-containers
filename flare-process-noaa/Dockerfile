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
    apt-get -yqq install jq \
        curl \
        libnetcdf-dev && \
    R -e "remotes::install_github('FLARE-forecast/rNOMADS@78b61c3fd0e47f456fdc20bf5c0dd0234b418710')" && \
    R -e "remotes::install_github('FLARE-forecast/noaaGEFSpoint@fc08f6272da5b7bdeec3b764050e490482d27240')"

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
RUN mkdir -p /home/user/flare/scripts/
COPY --chown=user:user flare-process-noaa/flare-container.sh /home/user/flare/
COPY --chown=user:user commons/commons.sh /home/user/flare/
RUN chmod +x /home/user/flare/flare-container.sh
COPY --chown=user:user flare-process-noaa/scripts/launch_download_downscale.R /home/user/flare/scripts/

# Start OpenWhisk Service
RUN mkdir /home/user/openwhisk/
WORKDIR /home/user/openwhisk/
RUN npm install && \
    npm install shelljs \
        nodemon \
        express
RUN mv /home/user/openwhisk/node_modules /home/user/node_modules
COPY --chown=user:user flare-process-noaa/. /home/user/openwhisk/
COPY --chown=user:user commons/flare_pullworkdir.sh /home/user/openwhisk/
COPY --chown=user:user commons/flare_pushworkdir.sh /home/user/openwhisk/
COPY --chown=user:user commons/flare_triggernext.sh /home/user/openwhisk/
EXPOSE 8080
CMD ["npm", "start"]
