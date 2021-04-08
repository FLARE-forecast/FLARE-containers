FROM rocker/tidyverse:4.0.3

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
	vim  \
	curl && \
	wget -O /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
	wget -O /usr/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc

# Copy Files to Container
RUN mkdir -p /root/flare/
COPY flare-container.sh /root/flare/
RUN wget https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/master/commons/commons.sh -O /root/flare/commons.sh
RUN chmod +x /usr/bin/yq /usr/bin/mc /root/flare/flare-container.sh
