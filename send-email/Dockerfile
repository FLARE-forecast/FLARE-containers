ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:22.04

# Install Dependencies
COPY send-email/package-versions.txt send-email/yq-version.txt /tmp/
RUN apt-get -yq update && \
    xargs -a /tmp/package-versions.txt apt-get -yqq install --no-install-recommends --yes
RUN yq_version=$(cat /tmp/yq-version.txt) && \
    wget --no-check-certificate "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64" -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Copy Files
COPY send-email/run-container.sh commons/source.sh send-email/*.yml /root/flare/
RUN chmod +x /root/flare/run-container.sh

# Set Entry Point
ENTRYPOINT /root/flare/run-container.sh ${CONFIG_FILE}
