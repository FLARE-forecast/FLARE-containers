FROM ubuntu:18.04

# Set FLARE user
RUN groupadd --gid 5000 user \
    && useradd --home-dir /home/user --create-home --uid 5000 \
        --gid 5000 --shell /bin/sh --skel /dev/null user


# Install packages
RUN apt-get update -y && apt-get install sudo wget s-nail vim -y
RUN wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Copy files
USER user
COPY --chown=user:user send-email/flare-container.sh /home/user/flare/
COPY --chown=user:user commons/commons.sh /home/user/flare/
RUN chmod +x /home/user/flare/flare-container.sh


WORKDIR /home/user/flare/
