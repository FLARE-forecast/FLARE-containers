FROM python:3

# Set Environment Variables
ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install jq && \
    wget -O /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    wget -O /usr/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && \
    pip3 install pycurl certifi PyYAML

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
RUN mkdir -p /root/flare/scripts/
COPY flare-container.sh /root/flare/
RUN wget -O /root/flare/commons.sh https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/master/commons/commons.sh
RUN chmod +x /usr/bin/yq /usr/bin/mc /root/flare/flare-container.sh
COPY /scripts/qdownloader.py /root/flare/scripts

# Start OpenWhisk Service
WORKDIR /code
COPY . /code
EXPOSE 8080
CMD ["npm", "start"]
