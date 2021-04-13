function rancher-logging() {

    echo "Starting rancher-logging setup"
    local namespace="cattle-logging-system"
    local LOGGING_DIR="$DIR/addons/rancher-logging/2.5"
    export HELM_TIMEOUT="600s"

    kubectl create namespace $namespace 2>/dev/null || true

    #Install logging CRDS
    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install rancher-logging-crd $LOGGING_DIR/rancher-logging-crd --namespace=cattle-logging-system

    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install rancher-logging $LOGGING_DIR/rancher-logging --namespace=cattle-logging-system -f $LOGGING_DIR/rancher-logging/values.yaml

    wait_till_rollout $namespace "deploy"

    echo "Rancher logging setup completed successfully"

}

