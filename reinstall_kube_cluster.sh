#!/bin/bash
# Inspired from https://opensource.com/article/20/2/live-demo-script
#set -e # Do not stop on erros

export FAAS_DIR=${HOME}/dev/FPGA_as_a_Service
mkdir -p ${FAAS_DIR}


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


pause "Reset cluster"
docmd sudo kubeadm reset -f

pause "Disable Swap"
docmd sudo swapoff -a

pause "Init master node"
docmd sudo kubeadm init --pod-network-cidr=10.244.0.0/16
docmd sudo mkdir -p /root/.kube
docmd sudo ln -sf /etc/kubernetes/admin.conf /root/.kube/config
docmd sudo netstat -nltp | grep apiserver


pause "Configure flannel"
docmd sudo sysctl net.bridge.bridge-nf-call-iptables=1
docmd sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
docmd sudo kubectl get pod -n kube-system -o wide


pause "Install k8s FPGA plugin"
docmd sudo kubectl taint nodes --all node-role.kubernetes.io/master-
docmd git clone https://github.com/Xilinx/FPGA_as_a_Service.git ${FAAS_DIR}
docmd sudo kubectl create -f ${FAAS_DIR}/k8s-fpga-device-plugin/fpga-device-plugin.yml
docmd sudo kubectl get pod -n kube-system
docmd sudo kubectl describe node `sudo kubectl get node -o jsonpath='{.items[0].metadata.name}'`
docmd sleep 2
docmd sudo kubectl describe node `sudo kubectl get node -o jsonpath='{.items[0].metadata.name}'`

pause "FPGA card status | need f1.* instance"
docmd sudo systemctl start mpd
docmd sudo systemctl status mpd
docmd sudo xbutil scan
