#!/bin/bash

# put this snippet at the bottom of your `$HOME/.bashrc`

# ssh-agent settings
# first, we only want to run if this is an interactive shell
if shopt -q login_shell; then #NOTE: This is a BASH builtin
  SSHAGSOCK="${HOME}/.ssh/ssh_auth_sock"
  SSHAGTMOUT=28800 # ssh-agent timeout (14400 = 4 hours)

  if [ ! -S "${SSHAGSOCK}" ] ; then
    eval "$(ssh-agent -t ${SSHAGTMOUT} -a ${SSHAGSOCK} > /dev/null)"
    echo "--- ssh-agent socket created ---"
  fi
  if [ -z "${SSH_AUTH_SOCK}" ] ; then
    export SSH_AUTH_SOCK="${SSHAGSOCK}"
    KEYOUT=$(ssh-add -l)
    echo "--- ${KEYOUT} ---"
  fi
fi
