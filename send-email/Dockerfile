ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:latest

# Install Dependencies
RUN apt-get -yq update && \
    apt-get -yqq install --no-install-recommends --yes vim=2:8.2.3995-1ubuntu2 \
    wget=1.21.2-2ubuntu1 \
    s-nail=14.9.23-1build1 && \
    wget --no-check-certificate https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Copy Files
COPY send-email/run-container.sh /root/flare/
COPY commons/source.sh /root/flare/
COPY send-email/*.yml /root/flare/
RUN chmod +x /root/flare/run-container.sh

ENTRYPOINT /root/flare/run-container.sh ${CONFIG_FILE}
