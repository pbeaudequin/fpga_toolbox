#!/bin/bash

set -e


pause() {
  local step="${1}"
  ps1
  echo -n "# Next step: ${step}"
  read
}

ps1() {
  echo -ne "\033[01;32m${USER}@$(hostname) \033[01;34m$(basename $(pwd)) \$ \033[00m"
}

echocmd() {
  echo "$(ps1)$@"
}

docmd() {
  echocmd $@
  $@
}

step0() {
  docmd echo 'Test'
}


pause "Setting up kube cluster"

pause "Reset cluster"
docmd kubeadmin reset

pause "Disable Swap"
docmd sudo swapoff -a

pause "Init master node"
docmd sudo kubeadm init --pod-network-cidr=10.244.0.0/16
docmd sudo mkdir -p $HOME/.kube