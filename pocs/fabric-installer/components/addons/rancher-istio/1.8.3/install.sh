function rancher-istio() {

    echo "Starting Istio setup"

    local namespace="istio-system"

    kubectl create namespace $namespace 2>/dev/null || true
    #istio-commons-crd creates a route in rook-ceph namespace as well
    kubectl create namespace rook-ceph 2>/dev/null || true
    #kubectl delete vs hello-virtual-service 2>/dev/null || true

    local ISTIO_DIR="$DIR/addons/rancher-istio/1.8.3"
    export HELM_TIMEOUT="600s"

    #check helm install status
    helm_uninstall_failed_release rancher-istio $namespace

    helm upgrade --atomic --force --wait --timeout ${HELM_TIMEOUT} --install rancher-istio $ISTIO_DIR/istio --namespace=$namespace -f $ISTIO_DIR/istio/values.yaml
    wait_till_rollout $namespace "deploy"

    #Installing cert manager to provision self sign cert
    install_component "certmanager" "1.2.0"

    discover_ip_addresses
    cd $DIR/addons/rancher-istio/
    mkdir -p /tmp
    sed "s/INGRESS_HOST/${PUBLIC_ADDRESS}/g" post-provisioning/self-sign-cert.yaml > /tmp/self-sign-cert.yaml

    #Generate self sign cert through cert manager
    kubectl -n $namespace apply -f post-provisioning/self-sign-issuer.yaml
    kubectl -n $namespace apply -f /tmp/self-sign-cert.yaml
    validate_certificate_status $namespace istio-ingressgateway-certs

    #Istio common configuration
    helm_uninstall_failed_release istio-commons-crd $namespace
    helm upgrade --atomic --force --wait --timeout 100s --install istio-commons-crd post-provisioning/istio-commons-crd --namespace $namespace
    kubectl apply -f $ISTIO_DIR/istio/samples/hello-world/

    kubectl -n $namespace patch svc istio-ingressgateway -p "$(cat post-provisioning/patch-istio-ingressgateway.yaml)"
    echo "Istio 1.8.3 setup completed successfully"

}


