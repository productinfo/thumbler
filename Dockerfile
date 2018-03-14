FROM node:8.10.0-alpine

ENV NODE_PATH /workspace/node_modules
ENV PATH $PATH:/workspace/node_modules/.bin

WORKDIR /workspace

RUN \
apk --update add dumb-init git openssh make gcc g++ python && \
rm -rf /var/lib/apt/lists/* && \
rm /var/cache/apk/*

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
