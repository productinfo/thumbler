#!/usr/bin/env sh
eval `ssh-agent`
cp /run/secrets/id_rsa /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa
stty -echo
ssh-add
stty +echo
