function rancher-server() {

    echo "Starting Rancher server setup"

    local RANCHER_DIR="$DIR/addons/rancher-server/2.5"
    local namespace="cattle-system"
    export HELM_TIMEOUT="600s"

    kubectl create namespace $namespace 2>/dev/null || true

    #Rancher server depends on cert-manager to provision self sign cert
    install_component "certmanager" "1.2.0"

    #check helm install status
    helm_uninstall_failed_release rancher-server $namespace

    hostname=$(hostname).uipath.com
    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install rancher-server $RANCHER_DIR/rancher --namespace=$namespace --set hostname=$hostname --set replicas=1

    wait_till_rollout $namespace "deploy"

    echo "Rancher server setup successfully completed"

}


