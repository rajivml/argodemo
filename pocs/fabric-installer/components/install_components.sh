#!/bin/bash

. $PWD/Modules/utils.sh
export DIR=$PWD/pocs/fabric-installer/components

########
#Copy Dependencies to bin folder, if the installer is triggered from the host machine 
########
function copy_dependencies() {

    if [ ! -f "/usr/local/bin/bcrypt" ]; then
        yum -y install unzip
        mkdir -p ~/downloads && wget -cO - https://github.com/rajivml/argodemo/raw/main/bin/libs.zip > ~/downloads/libs.zip && unzip -o ~/downloads/libs.zip -d ~/downloads/ && rm -f ~/downloads/libs.zip
        chmod +x ~/downloads/*
        mkdir -p /usr/local/bin && mkdir -p "$DIR"/bin
        cp -ru ~/downloads/* /usr/local/bin
        cp -ru ~/downloads/* "$DIR"/bin
    fi
    PATH=$PATH:/usr/local/bin
    export PATH
}

########
# To make sure all the pre conditions are satisfied
########
function preflights() {
    discover_ip_addresses
    patch_default_storage_class
    return 0
}

########
# Helper method to install target component (Ex: CEPH, Istio, Rabbitmq etc.)
# Arguments:
#   componenetName
#   componenetVersion
########
function install_component() {
    componenetName=$1
    componenetVersion=$2

    if [ -z "$componenetName" ]; then
        error "component name is missing"
    fi

    if [ -z "$componenetVersion" ]; then
        error "component version is missing"
        return 0
    fi

    log_step "Addon $componenetName $version"

    rm -rf "$DIR"/kustomize/"$componenetName"
    mkdir -p "$DIR"/kustomize/"$componenetName"

    . $DIR/addons/$componenetName/$componenetVersion/install.sh

    #this is where the addon install trigger happens
    $componenetName

}

function main() {
    #Useful to check if it's a local install vs docker based install
    RKE2_CONFIG=/etc/rancher/rke2/rke2.yaml

    #To enable triggering script through host machine as well as through docker
    if [ -f "$RKE2_CONFIG" ]; then
       export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH=$PATH:/var/lib/rancher/rke2/bin
       require_root_user
       copy_dependencies

       if [ ! -f "/usr/local/bin/s3cmd" ]; then
          pip3 install s3cmd
	  dnf install -y jq openssl httpd-tools
          export PATH=$PATH:/usr/local/bin/s3cmd
       else
          export PATH=$PATH:/usr/local/bin/s3cmd       
       fi
    fi

    if [[ $# -eq 0 ]] ; then
       error 'Component Name and version args are required'
    fi

    componentName=$1
    componentVersion=$2

    if [ -z "$componentName" ]; then
        error "component name is missing"
    fi

    if [ -z "$componentVersion" ]; then
        error "component version is missing"
    fi

    #require_root_user
    preflights
    install_component "$componentName" "$componentVersion"
}

main "$@"
