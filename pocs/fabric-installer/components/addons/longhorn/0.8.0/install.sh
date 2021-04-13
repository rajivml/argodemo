
function longhorn() {

    echo "Starting longhorn setup"

    #copy longhorn yaml to dst folder
    local dst="$DIR/kustomize/longhorn"
    local LONGHORN_DIR="$DIR/addons/longhorn/0.8.0"
    local namespace="longhorn-system"

    mkdir -p $dst
    cp $LONGHORN_DIR/longhorn.yaml $dst/longhorn.yaml

    # Deploy longhorn
    kubectl -n $namespace apply -f $dst/longhorn.yaml

    #wait for deployment to be complete
    wait_till_rollout $namespace "deploy"
    
    echo "longhorn deployment completed successfully"

}

