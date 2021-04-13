function rabbitmq() {

    echo "Starting rabbitmq setup"  

    local RABBITMQ_DIR="$DIR/addons/rabbitmq/3.8.14"
    local namespace="rabbitmq"
    local release_name="rabbitmq"
    export HELM_TIMEOUT="600s"

    kubectl create namespace $namespace 2>/dev/null || true

    helm_uninstall_failed_release $namespace $release_name

    rabbitmq=$(kubectl -n $namespace get secret rabbitmq | grep "rabbitmq" | cut -d ' ' -f1)

    if [ "${rabbitmq}" = "rabbitmq" ];
    then
      echo "RabbitMQ already exists !!"
      export RABBITMQ_PASSWORD=$(kubectl get secret -n $namespace rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)
      export RABBITMQ_ERLANG_COOKIE=$(kubectl get secret -n $namespace rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)
      helm upgrade --atomic --wait --timeout $HELM_TIMEOUT --install rabbitmq $RABBITMQ_DIR/rabbitmq --namespace $namespace --set volumePermissions.image.pullPolicy="IfNotPresent" --set auth.password=$RABBITMQ_PASSWORD \
	      --set auth.erlangCookie=$RABBITMQ_ERLANG_COOKIE -f $RABBITMQ_DIR/rabbitmq/values-onebox.yaml
    else
      helm upgrade --atomic --wait --timeout $HELM_TIMEOUT --install rabbitmq $RABBITMQ_DIR/rabbitmq --namespace $namespace --set volumePermissions.image.pullPolicy="IfNotPresent" -f $RABBITMQ_DIR/rabbitmq/values-onebox.yaml
    fi

    #wait for deployment to be complete
    kubectl -n $namespace rollout status statefulset/rabbitmq
    kubectl wait --namespace=rabbitmq --for=condition=ready pod --timeout=600s -l statefulset.kubernetes.io/pod-name=rabbitmq-0
    label_object $namespace secret rabbitmq

    echo "RabbitMQ setup completed successfully"

}
