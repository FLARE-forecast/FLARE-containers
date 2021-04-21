FROM rocker/geospatial:4.0.4

# Set Environment Variables
ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive

# Install Dependencies
RUN R -e "remotes::install_github('FLARE-forecast/rNOMADS@78b61c3fd0e47f456fdc20bf5c0dd0234b418710')" && \
    R -e "remotes::install_github('FLARE-forecast/noaaGEFSpoint@fc08f6272da5b7bdeec3b764050e490482d27240')" && \
    wget -O /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /usr/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc

# Install Node
ENV NODE_VERSION=14.16.1
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm install && \
    npm install shelljs \
        nodemon \
        express

# Copy Files to Container
RUN mkdir -p /root/flare/rscripts/
COPY flare-container.sh /root/flare/
RUN wget -O /root/flare/commons.sh https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/21.01.4/commons/commons.sh
RUN chmod +x /usr/bin/yq /usr/bin/mc /root/flare/flare-container.sh
COPY rscripts/launch_download_downscale.R /root/flare/rscripts/

# Start OpenWhisk Service
WORKDIR /code
COPY . /code
EXPOSE 8080
CMD ["npm", "start"]

