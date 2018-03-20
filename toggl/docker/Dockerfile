FROM node:8.10.0-alpine

ENV NODE_PATH /workspace/node_modules
ENV PATH $PATH:/workspace/node_modules/.bin

WORKDIR /workspace

RUN \
apk --no-cache add dumb-init vim tmux git openssh make gcc g++ python

#COPY ./yarnrc /usr/local/share/.yarnrc
COPY ./authorize.sh /usr/local/bin/ssh-auth

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
