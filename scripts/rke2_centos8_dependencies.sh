#!/bin/bash
set -e

# set variables
YUM_PACKAGES="unzip container-selinux rke2-server rke2-agent"
#RKE_IMAGES_DL_URL="https://github.com/rancher/rke2/releases/download/v1.18.12%2Brke2r1/rke2-images.linux-amd64.tar.gz"
#RKE_IMAGES_DL_SHASUM="https://github.com/rancher/rke2/releases/download/v1.18.12%2Brke2r1/sha256sum-amd64.txt"
RKE_IMAGES_DL_URL="https://github.com/rancher/rke2/releases/download/v1.18.12%2Brke2r2/rke2-images.linux-amd64.tar.gz"
RKE_IMAGES_DL_SHASUM="https://github.com/rancher/rke2/releases/download/v1.18.12%2Brke2r2/sha256sum-amd64.txt"
RKE2_VERSION="1.18"

# preflight - check for centos-8 and root user
if ! ( [[ $(awk -F= '/^ID=/{print $2}' /etc/os-release) = "\"centos\"" ]] && [[ $(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release) = "\"8\"" ]] ) ; then 
  echo "needs to be run on centos 8"; 
  exit 1; 
fi
if [ "$EUID" -ne 0 ] ; then
  echo "needs to be run as root"; 
  exit 1; 
fi

# create a working directory, install dependency collection dependencies
export workdir=rke-government-deps-$(date +"%y-%m-%d-%H-%M-%S");
mkdir $workdir;
cd $workdir;
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum install -y yum-utils createrepo unzip wget;

#Install moduletools https://unix.stackexchange.com/questions/567057/download-rpm-and-all-dependencies-on-rhel-centos-8
wget -O modulemd-tools.rpm http://ftp.riken.jp/Linux/fedora/epel/8/Everything/x86_64/Packages/m/modulemd-tools-0.6-1.el8.noarch.rpm
dnf -y install modulemd-tools.rpm
rm modulemd-tools-0.6-1.el8.noarch.rpm

#Install python3 for module-tools
dnf -y install python3
dnf -y install pkg-config

#for moduletools gi library
wget https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/p/python36-gobject-base-3.22.0-6.el7.x86_64.rpm
dnf -y install python36-gobject-base-3.22.0-6.el7.x86_64.rpm
rm python36-gobject-base-3.22.0-6.el7.x86_64.rpm

# grab and verify rke images
curl -LO ${RKE_IMAGES_DL_URL};
curl -LO ${RKE_IMAGES_DL_SHASUM};
CHECKSUM_EXPECTED=$(grep "rke2-images.linux-amd64.tar.gz" "sha256sum-amd64.txt" | awk '{print $1}');
CHECKSUM_ACTUAL=$(sha256sum "rke2-images.linux-amd64.tar.gz" | awk '{print $1}');
if [ "${CHECKSUM_EXPECTED}" != "${CHECKSUM_ACTUAL}" ]; then echo "FATAL: download sha256 does not match"; exit 1; fi
rm -f sha256sum-amd64.txt


# install rke rpm repo
cat <<-EOF >"/etc/yum.repos.d/rancher-rke2-latest.repo"
[rancher-rke2-common-latest]
name=Rancher RKE2 Common (latest)
baseurl=https://rpm.rancher.io/rke2/latest/common/centos/8/noarch
enabled=0
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
[rancher-rke2-latest]
name=Rancher RKE2 ${RKE2_VERSION} (latest)
baseurl=https://rpm.rancher.io/rke2/latest/${RKE2_VERSION}/centos/8/x86_64
enabled=0
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF

# install hashicorp repo
cat <<-EOF >"/etc/yum.repos.d/hashicorp.repo"
[hashicorp]
name=Hashicorp Stable
baseurl=https://rpm.releases.hashicorp.com/RHEL/8/\$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF

#Install kubectl
cat <<-EOF >"/etc/yum.repos.d/kubernetes.repo"
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=0
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# download all rpms and their dependencies
mkdir rke_rpm_deps;
cd rke_rpm_deps;
echo "y" | yum -y install --enablerepo="rancher-rke2-common-latest" --enablerepo="hashicorp" --enablerepo="rancher-rke2-latest" --enablerepo="kubernetes" --releasever=/ --installroot=$(pwd) --downloadonly --downloaddir $(pwd) ${YUM_PACKAGES};
createrepo -v .;
# create traditional rpm repo
createrepo_c .
# generate modules meta info
repo2module  -s stable -d . modules.yaml
# adjust modules meta info to traditional rpm repo
modifyrepo_c --mdtype=modules modules.yaml repodata/
cd ..;
tar -zcvf rke_rpm_deps.tar.gz rke_rpm_deps;
rm -rf rke_rpm_deps;

# create tar with everything, delete working directory
tar -zcvf ../$workdir.tar.gz .;
cd ..;
rm -rf $workdir;
echo $workdir.tar.gz;
