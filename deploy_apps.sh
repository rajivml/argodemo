function discover_private_ip() {
    PRIVATE_ADDRESS=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')

    #This is needed on k8s 1.18.x as $PRIVATE_ADDRESS is found to have a newline
    PRIVATE_ADDRESS=$(echo "$PRIVATE_ADDRESS" | tr -d '\n')
}

function argocd_login() {
ARGO_PORT=$(kubectl -n argocd get svc argocd-server -o=jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD="XXXX"
/usr/local/bin/argocd login --insecure $PRIVATE_ADDRESS:$ARGO_PORT --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD
}


function install_app() {
APP_NAME=$1
APP_PATH=$2
DEST_NAMESPACE=$3
RELEASE_NAME=$1

#Fetch GIT server IP through kubectl
/usr/local/bin/argocd app create $APP_NAME --repo http://xx.xx.17.8:32152/gitea_admin/argocddemo --release-name $RELEASE_NAME --path $APP_PATH --dest-server https://kubernetes.default.svc --revision main --dest-namespace guestbook --upsert --values values.yaml --name $DEST_NAMESPACE  --sync-option CreateNamespace=true

#Fetch Registry URL through kubectl
/usr/local/bin/argocd app set $APP_NAME -p registry.url=xx.xx.31.128 

/usr/local/bin/argocd app sync $APP_NAME 
app_exit_status=$(/usr/local/bin/argocd app wait $APP_NAME --timeout 300)

#If exit status is successful, app is in health state
#if exit status is greater than 0
#then fetch app_health 
app_health=$(/usr/local/bin/argocd app get $APP_NAME -o json  | jq -r '.status.health.status')
# if app health is degraded then that implies something wrong with the deployment
# exit 1 and bail out the deployment
# kubectl -n $NAMESPACE get all -A
# https://argoproj.github.io/argo-rollouts/
}

function delete_app() {
APP_NAME=$1
/usr/local/bin/argocd app delete $APP_NAME
}


function main() {
    #Read config map to figure out what all apps have to be installed, the namespace in which they have to be installed, the git path, release name etc details
    #loop through those apps one by one and call install_app for each app
    #Shall we install common software component also via this approach ?

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    discover_private_ip
    argocd_login
}

main "$@"




