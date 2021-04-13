
function rook-ceph() {

    echo "Starting ceph setup"

    # copy ceph yaml to dst folder
    local CEPH_DIR="$DIR/addons/rook-ceph/1.5.9"
    export HELM_TIMEOUT="600s"
    namespace="uipath-default"


    #check helm install status
    helm_uninstall_failed_release rook-ceph $namespace

    helm upgrade --atomic --wait --timeout ${HELM_TIMEOUT} --install rook-ceph $CEPH_DIR/rook-ceph --namespace=$namespace --set csi.enableRbdDriver=false --set csi.enableCephfsDriver=false --set csi.enableCephfsSnapshotter=false --set csi.enableRBDSnapshotter=false
    wait_till_rollout $namespace "deploy"
    # Deploy ceph
    kubectl -n $namespace apply -f $CEPH_DIR/post-provisioning/cluster-on-pvc.yaml
    kubectl -n $namespace apply -f $CEPH_DIR/post-provisioning/object.yaml
    kubectl -n $namespace apply -f $CEPH_DIR/post-provisioning/toolbox.yaml

    #wait for deployment to be complete
    wait_till_rollout $namespace "deploy"
    wait_for_pod_ready $namespace rook-ceph-rgw

    export_endpoints
    ceph_health
    ceph_create_admin
    object_store_create_bucket testbucket
    echo "ceph deployment completed successfully"
}


function ceph_health() {

    echo "Polling for rook RGW Pod"
    if ! spinner_until 120 rook_rgw_is_healthy; then
        error "Failed to detect healthy Rook RGW"
    fi
}


function export_endpoints() {
    OBJECT_STORE_CLUSTER_IP=$(kubectl -n $namespace get service rook-ceph-rgw-rook-ceph | tail -n1 | awk '{ print $3}')
    OBJECT_STORE_CLUSTER_HOST="http://rook-ceph-rgw-rook-ceph.rook-ceph"

    OBJECT_GATEWAY_INTERNAL_HOST=$(kubectl -n $namespace get services/rook-ceph-rgw-rook-ceph -o jsonpath="{.spec.clusterIP}")
    OBJECT_GATEWAY_INTERNAL_PORT=$(kubectl -n $namespace get services/rook-ceph-rgw-rook-ceph -o jsonpath="{.spec.ports[0].port}")
    #CEPH Gateway External Access Via Istio Ingress Gateway (Signed URL Based Upload)
    OBJECT_GATEWAY_EXTERNAL_HOST=$PUBLIC_ADDRESS
    OBJECT_GATEWAY_EXTERNAL_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
}

function ceph_create_admin() {

    rook_ceph_deploy=$(kubectl -n $namespace get deploy | grep rook-ceph-tools | cut -d ' ' -f1)
    toolbox_pod=$(kubectl -n $namespace get pod -l app=rook-ceph-tools -o jsonpath="{.items[0].metadata.name}")
    #Create User
    #Reading it to a variable just to ensure the output with keys(sensitive info) is not printed to the console
    USER_CREATED=$(kubectl -n $namespace exec -it $toolbox_pod -- sh -c 'radosgw-admin user create --uid=admin --display-name="admin user" --system' 2>/dev/null || true)
    #fetch credentials for system user
    OBJECT_STORE_USER=$(kubectl -n $namespace exec -it $toolbox_pod -- sh -c 'radosgw-admin user info --uid=admin')
    OBJECT_STORE_ACCESS_KEY=$(eval echo $(echo $OBJECT_STORE_USER | jq '.keys[0].access_key'))
    OBJECT_STORE_SECRET_KEY=$(eval echo $(echo $OBJECT_STORE_USER | jq '.keys[0].secret_key'))

    if ! $(object_store_exists); then
      error "Object store credentials were not configured properly";
    fi

    #Delete Storage Secret if Exists
    kubectl -n $namespace delete secret ceph-object-store-secret 2>/dev/null || true

    #Create Storage Secret with Updated Values
    kubectl -n $namespace create secret generic ceph-object-store-secret --from-literal=OBJECT_STORAGE_ACCESSKEY=$OBJECT_STORE_ACCESS_KEY --from-literal=OBJECT_STORAGE_SECRETKEY=$OBJECT_STORE_SECRET_KEY --from-literal=OBJECT_STORAGE_HOST=$OBJECT_GATEWAY_INTERNAL_HOST --from-literal=OBJECT_STORAGE_PORT=$OBJECT_GATEWAY_INTERNAL_PORT --from-literal=OBJECT_STORAGE_EXTERNAL_HOST=$OBJECT_GATEWAY_EXTERNAL_HOST --from-literal=OBJECT_STORAGE_EXTERNAL_PORT=$OBJECT_GATEWAY_EXTERNAL_PORT

    label_object $namespace secret ceph-object-store-secret

}


function rook_rgw_is_healthy() {
    curl --noproxy "*" --fail --silent --insecure "http://${OBJECT_STORE_CLUSTER_IP}" > /dev/null
}

