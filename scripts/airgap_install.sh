KUBECONFIG=/etc/rancher/rke2/rke2.yaml
PATH=${PATH}:/var/lib/rancher/rke2/bin

wait_for_healthy(){
        until KUBECONFIG=/etc/rancher/rke2/rke2.yaml kubectl cluster-info | grep running
        do
          sleep 5
        done
        KUBECONFIG=/etc/rancher/rke2/rke2.yaml /home/sshuser/scripts/k9s -n all
}

FOLDER_PATH=/home/sshuser
#untar rancher images
tar xzvf ${FOLDER_PATH}/RKE_Dependencies/rke-government-deps-*.tar.gz -C ${FOLDER_PATH}/RKE_Dependencies

mkdir -p /var/lib/rancher/rke2/agent/images/ && \
zcat ${FOLDER_PATH}/RKE_Dependencies/rke2-images.linux-amd64.tar.gz > /var/lib/rancher/rke2/agent/images/rke2-images.linux-amd64.tar
#copy other dependencies
zcat ${FOLDER_PATH}/other_deps.tar.gz > /var/lib/rancher/rke2/agent/images/other_deps.tar


mkdir -p /var/lib/rancher/yum_repos
tar xzf ${FOLDER_PATH}/RKE_Dependencies/rke_rpm_deps.tar.gz -C /var/lib/rancher/yum_repos


mkdir -p /etc/rancher/rke2

cat > /etc/rancher/rke2/config.yaml <<EOF
selinux: true
write-kubeconfig-mode: "0644"
EOF

cat > /etc/yum.repos.d/rke_rpm_deps.repo <<EOF
[rke_rpm_deps]
name=rke_rpm_deps
baseurl=file:///var/lib/rancher/yum_repos/rke_rpm_deps
enabled=0
gpgcheck=0
EOF

yum -y install --disablerepo=* --enablerepo="rke_rpm_deps" rke2-server


systemctl enable rke2-server
systemctl start rke2-server

wait_for_healthy
KUBECONFIG=/etc/rancher/rke2/rke2.yaml /home/sshuser/scripts/k9s -n all
