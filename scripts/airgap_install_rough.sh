KUBECONFIG=/etc/rancher/rke2/rke2.yaml
PATH=${PATH}:/var/lib/rancher/rke2/bin

wait_for_healthy(){
	until KUBECONFIG=/etc/rancher/rke2/rke2.yaml kubectl cluster-info | grep Running
	do
	  sleep 5
	done 
	KUBECONFIG=/etc/rancher/rke2/rke2.yaml /home/sshuser/k9s -n all
}

#untar rancher images 
tar xzvf rke-government-deps-*.tar.gz

mkdir -p /var/lib/rancher/rke2/agent/images/ && \
zcat rke2-images.linux-amd64.tar.gz > /var/lib/rancher/rke2/agent/images/rke2-images.linux-amd64.tar


mkdir -p /var/lib/rancher/yum_repos
tar xzf rke_rpm_deps.tar.gz -C /var/lib/rancher/yum_repos


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

yum install --disablerepo=* --enablerepo="rke_rpm_deps" rke2-server


systemctl enable rke2-server
systemctl start rke2-server

wait_for_healthy
KUBECONFIG=/etc/rancher/rke2/rke2.yaml /home/sshuser/k9s -n all
