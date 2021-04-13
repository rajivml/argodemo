
function argocd() {

    echo "Starting argocd setup"
    local namespace="argocd"
    kubectl create namespace $namespace 2>/dev/null || true
 
    local ARGO_DIR="$DIR/addons/argocd/1.8.7"
    
    kubectl -n $namespace apply -f $ARGO_DIR/install.yaml
    kubectl -n $namespace apply -f $ARGO_DIR/argocd-cm.yaml 2>/dev/null || true

    #wait for deployment to be complete
    wait_till_rollout $namespace "deploy"
    kubectl -n $namespace wait --for=condition=available deployment --all --timeout=600s
    kubectl -n $namespace rollout status statefulset/argocd-application-controller

    echo "argocd deployment completed successfully"

}

