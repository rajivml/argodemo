function rancher-monitoring() {

    echo "Starting rancher-monitoring setup"

    local MONITORING_DIR="$DIR/addons/rancher-monitoring/2.5"
    local namespace="cattle-monitoring-system"
    export HELM_TIMEOUT="600s"

    kubectl create namespace cattle-monitoring-system 2>/dev/null || true
    local dst="$DIR/kustomize/rancher-monitoring"
    mkdir -p $dst

    #Install monitoring CRDS
    helm_uninstall_failed_release rancher-monitoring-crd $namespace
    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install rancher-monitoring-crd $MONITORING_DIR/rancher-monitoring-crd --namespace=$namespace

    helm_uninstall_failed_release rancher-monitoring $namespace
    helm upgrade --wait --timeout ${HELM_TIMEOUT} --install rancher-monitoring $MONITORING_DIR/rancher-monitoring --namespace=$namespace
    wait_till_rollout $namespace "deploy"

    echo "Rancher Monitoring setup completed successfully"

}

