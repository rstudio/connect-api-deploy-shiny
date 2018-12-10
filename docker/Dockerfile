FROM ubuntu:bionic
MAINTAINER RStudio Connect <rsconnect@rstudio.com>

RUN export DEBIAN_FRONTEND=noninteractive && \
        apt-get update && \
        apt-get install -y \
        bash \
        curl \
        jq

# Start in /content, a mounted volume expected to contain our content.
WORKDIR /content
