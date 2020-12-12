#!/bin/sh


yum remove -y 'rke2-*'
rm -rf /run/k3s

curl -sL https://raw.githubusercontent.com/rancher/rke2/488bab0f48b848e408ce399c32e7f5f73ce96129/bundle/bin/rke2-uninstall.sh --output rke2-uninstall.sh
chmod +x rke2-uninstall.sh
mv rke2-uninstall.sh /usr/local/bin

curl -sL https://raw.githubusercontent.com/rancher/rke2/488bab0f48b848e408ce399c32e7f5f73ce96129/bundle/bin/rke2-killall.sh --output rke2-killall.sh
chmod +x rke2-killall.sh
mv rke2-killall.sh /usr/local/bin

bash rke2-uninstall.sh
