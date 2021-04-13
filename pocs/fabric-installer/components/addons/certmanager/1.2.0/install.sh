function certmanager() {

    echo "Starting Cert Manager setup"
    export HELM_TIMEOUT="600s"

    local CERT_MANAGER_DIR="$DIR/addons/certmanager/1.2.0"
    local namespace="cert-manager"

    kubectl create namespace $namespace 2>/dev/null || true

    helm_uninstall_failed_release $namespace cert-manager

    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install cert-manager $CERT_MANAGER_DIR/certmanager --namespace=$namespace --set installCRDs=true
    wait_till_rollout $namespace "deploy"

    echo "Cert Manager 1.2.0 setup completed successfully"

}



