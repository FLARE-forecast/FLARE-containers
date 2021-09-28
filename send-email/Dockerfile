FROM ubuntu:18.04

RUN apt-get update -y && apt-get install sudo wget s-nail -y
RUN wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

RUN mkdir -p /home/user/s-nail/
WORKDIR /home/user/s-nail/
