FROM sameersbn/gitlab-ci-multi-runner:1.1.4-7
MAINTAINER Michał "rysiek" Woźniak <rysiek@occrp.org>

#
# a Gitlab CI container to be used with Jekyll static site generator
#

# environment
ENV DEBIAN_FRONTEND=noninteractive 

# need en_US.UTF-8 locale for SASS to handle UTF-8 characters in CSS
# http://code.dblock.org/2011/06/09/compass-invalid-us-ascii-character-xe2.html
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Ruby and requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
        gcc \
        g++ \
        libc-dev-bin \
        libc6-dev \
        linux-libc-dev \
        libc6 \
        software-properties-common \
        nodejs && \
    rm -rf /var/lib/apt/lists/*

# need a newer Ruby
RUN add-apt-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ruby2.4 \
        ruby2.4-dev && \
    rm -rf /var/lib/apt/lists/*
    
# we might need to install some packages, but doing this in the entrypoint doesn't make any sense
ARG INSTALL_PACKAGES=
RUN if [ "$INSTALL_PACKAGES" != "" ]; then \
        export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y \
            $INSTALL_PACKAGES \
            --no-install-recommends && \
        rm -rf /var/lib/apt/lists/* ; \
    fi
    
# Jekyll
RUN gem2.4 install jekyll bundle

VOLUME /output
