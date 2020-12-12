#!/bin/bash
set -e

# -------- other start -----------
#dependencies to parse the yaml 
pip3 install yq
pip3 install jq

rm -rf other_deps
mkdir other_deps
cd other_deps

#Fetch argocd yaml
curl -LO https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

#Save argocd images 
images=(`cat install.yaml | yq -r '..|.image? | select(.)' | sort | uniq`)
for image in ${images[@]};
do
  save_image=$(echo $image | rev | cut -d'/' -f1 | rev | tr ':' '_')
  docker pull ${image}
  #docker save ${image} | gzip > ${save_image}.tar.gz
  docker save ${image} > ${save_image}.tar
  tar xvf ${save_image}.tar
  rm ${save_image}.tar
done

#Package other_deps folder
cd ..;
tar -zcvf other_deps.tar.gz other_deps;
rm -rf other_deps;

# -------- other end -----------

#----------------- scripts start ####################
rm -rf scripts
mkdir scripts
cd scripts
curl -sL https://raw.githubusercontent.com/rancher/rke2/488bab0f48b848e408ce399c32e7f5f73ce96129/bundle/bin/rke2-uninstall.sh --output rke2-uninstall.sh
chmod +x rke2-uninstall.sh

curl -sL https://raw.githubusercontent.com/rancher/rke2/488bab0f48b848e408ce399c32e7f5f73ce96129/bundle/bin/rke2-killall.sh --output rke2-killall.sh
chmod +x rke2-killall.sh

#download k9s 
curl -sL https://github.com/derailed/k9s/releases/download/v0.24.2/k9s_Linux_x86_64.tar.gz
sleep 5
tar xzvf k9s_Linux_x86_64.tar.gz
rm k9s.tar.gz
rm k9s_Linux_x86_64.tar.gz
rm LICENSE
rm README.md

cd ..
#----------------- scripts end ####################
