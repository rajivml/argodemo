function registry() {

    echo "Starting registry setup"

    namespace="uipath-default"

    kubectl create namespace $namespace 2>/dev/null || true

    local REGISTRY_DIR="$DIR/addons/registry/2.7.1"
    export HELM_TIMEOUT="600s"

    #check helm install status
    helm_uninstall_failed_release docker-registry $namespace

    DOCKER_REGISTRY_IP=10.43.10.10
    namespace="uipath-default"

    kubectl -n $namespace apply -f $REGISTRY_DIR/pre-provisioning/self-signed-issuer.yaml
    kubectl -n $namespace apply -f $REGISTRY_DIR/pre-provisioning/self-signed-cert.yaml
    validate_certificate_status $namespace docker-registry-cert

    registry_cred_secrets

    htpasswd_val=$(kubectl get secret -n uipath-default docker-registry-config -o jsonpath='{.data.REGISTRY_HTPASSWD}' | base64 -d)
    helm upgrade --atomic --wait --timeout ${HELM_TIMEOUT} --install docker-registry $REGISTRY_DIR/docker-registry --namespace=$namespace --set persistence.enabled=true --set persistence.size=200Gi --set tlsSecretName=docker-registry-cert --set ingress.enabled=true --set service.port=443 --set service.clusterIP=$DOCKER_REGISTRY_IP --set secrets.htpasswd=$htpasswd_val
    
    wait_till_rollout $namespace "deploy"

    echo "Registry 2.7.1 setup completed successfully"

}

function registry_cred_secrets() {

    if kubernetes_resource_exists $namespace secret registry-creds && kubernetes_resource_exists $namespace secret docker-registry-config; then
        return 0
    fi

    kubectl -n $namespace delete secret docker-registry-config &>/dev/null || true
    kubectl -n $namespace delete secret registry-creds &>/dev/null || true

    user=docker-registry
    password=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c9)
    htpasswd_val=$(htpasswd -Bbn $user $password)

    kubectl -n $namespace create secret docker-registry registry-creds \
        --docker-server="$DOCKER_REGISTRY_IP" \
        --docker-username="$user" \
        --docker-password="$password"

    REGISTRY_CERT=aGVsbG8
    REGISTRY_CREDENTIALS=$(kubectl get secret -n $namespace registry-creds -o jsonpath='{.data.\.dockerconfigjson}')
    REGISTRY_CREDENTIALS_PULL=$(kubectl get secret -n $namespace registry-creds -o jsonpath='{.data.\.dockerconfigjson}')
    REGISTRY_CREDENTIALS=$(echo { \"username\": "$user", \"password\": "$password", \"email\": \"email@domain.com\", \"registryUrl\": \"$DOCKER_REGISTRY_IP\" } | base64 -w 0)

    kubectl -n $namespace create secret generic docker-registry-config --from-literal=REGISTRY_HOST="$DOCKER_REGISTRY_IP" --from-literal=REGISTRY_USERNAME=$user --from-literal=REGISTRY_PASSWORD=$password --from-literal=REGISTRY_CREDENTIALS=$REGISTRY_CREDENTIALS --from-literal=REGISTRY_CREDENTIALS_PULL=$REGISTRY_CREDENTIALS_PULL --from-literal=REGISTRY_HTPASSWD="$htpasswd_val"

    kubectl -n $namespace label secret docker-registry-config secret-copier=yes 2>/dev/null || true
}	
