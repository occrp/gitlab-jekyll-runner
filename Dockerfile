FROM gitlab/gitlab-runner:ubuntu
MAINTAINER Michał "rysiek" Woźniak <rysiek@occrp.org>

#
# a Gitlab CI container to be used with Jekyll static site generator
#

# environment
ENV DEBIAN_FRONTEND=noninteractive 

# uid and gid of the gitlab-runner user
ARG GITLAB_RUNNER_UID=999
ARG GITLAB_RUNNER_GID=999

# open files limit needs to be bumped
COPY open-file-limit.conf /etc/security/limits.d/

# and let's modify the group and the user
RUN groupmod --gid ${GITLAB_RUNNER_GID} gitlab-runner \
    && usermod --uid "${GITLAB_RUNNER_UID}" gitlab-runner

# we need this to be able to handle the node repo setup
RUN DEBIAN_FRONTEND=noninteractive apt-get -q update && \
        apt-get -q -y --no-install-recommends install \
            gnupg \
            apt-transport-https \
            ca-certificates \
            locales \
            lsb-release && \
        apt-get -q clean && \
        apt-get -q -y autoremove && \
        rm -rf /var/lib/apt/lists/*

# need en_US.UTF-8 locale for SASS to handle UTF-8 characters in CSS
# http://code.dblock.org/2011/06/09/compass-invalid-us-ascii-character-xe2.html
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8

# add the node repo key
COPY node-repo-key.asc /tmp/node-repo-key.asc
RUN apt-key add /tmp/node-repo-key.asc

# add the node repo
RUN echo "deb https://deb.nodesource.com/node_8.x xenial main\ndeb-src https://deb.nodesource.com/node_8.x xenial main\n" > /etc/apt/sources.list.d/node_8.x.list

# adding additional repository keys from build args
ARG ADD_REPOSITORY_KEYS=
RUN if [ "$ADD_REPOSITORY_KEYS" != "" ]; then \
        echo "$ADD_REPOSITORY_KEYS" | sed -e 's/^[[:space:]]*//' | apt-key add - ; \
    fi

# adding repositories from build args
ARG ADD_REPOSITORIES=
RUN if [ "$ADD_REPOSITORIES" != "" ]; then \
        echo "$ADD_REPOSITORIES" | sed -e 's/^[[:space:]]*//' > /etc/apt/sources.list.d/added-from-docker-build-arg.list ; \
    fi

# Ruby and requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        gcc \
        g++ \
        libc-dev-bin \
        libc6-dev \
        linux-libc-dev \
        libc6 \
        software-properties-common \
        rsync \
        imagemagick \
        nodejs && \
    rm -rf /var/lib/apt/lists/*

# npm's self-signed CA is no more
# https://blog.npmjs.org/post/78085451721/npms-self-signed-certificate-is-no-more
RUN npm config -g set ca ""

# need a newer Ruby
RUN add-apt-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ruby2.6 \
        ruby2.6-dev && \
    rm -rf /var/lib/apt/lists/*

# we might need to install some packages, but doing this in the entrypoint doesn't make any sense
ARG INSTALL_PACKAGES=
RUN if [ "$INSTALL_PACKAGES" != "" ]; then \
        export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y \
            $INSTALL_PACKAGES \
            --no-install-recommends && \
        rm -rf /var/lib/apt/lists/* ; \
    fi

# Jekyll-related requirements
RUN gem2.6 install jekyll:'<4' bundler:'<2'
RUN /usr/bin/npm install bower -g

# copy in the entrypoint script
COPY entrypoint /
RUN chmod +x /entrypoint

VOLUME ["/etc/gitlab-runner", "/home/gitlab-runner", "/output"]
