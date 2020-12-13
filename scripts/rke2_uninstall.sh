#!/bin/sh


yum remove -y 'rke2-*'
rm -rf /run/k3s

chmod +x rke2-uninstall.sh
bash rke2-uninstall.sh

chmod +x rke2-killall.sh
bash rke2-killall.sh
