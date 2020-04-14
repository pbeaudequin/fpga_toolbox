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


#pause "Setting up kube cluster"

pause "Reset cluster"
docmd sudo kubeadm reset -f

pause "Disable Swap"
docmd sudo swapoff -a

pause "Init master node"
docmd sudo kubeadm init --pod-network-cidr=10.244.0.0/16
docmd sudo mkdir -p $HOME/.kube /root/.kube
docmd sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
docmd sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
docmd sudo chown $(id -u):$(id -g) $HOME/.kube/config
docmd sudo netstat -nltp | grep apiserver


pause "Configure flannel"
docmd sudo sysctl net.bridge.bridge-nf-call-iptables=1
docmd kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
docmd sudo kubectl get pod -n kube-system -o wide


pause "Install k8s FPGA plugin"
docmd sudo kubectl taint nodes --all node-role.kubernetes.io/master-
