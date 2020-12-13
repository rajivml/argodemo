namespaces=(`kubectl get namespaces --output=jsonpath='{.items[*].metadata.name}' | xargs -n1`)

for namespace in ${namespaces[@]};
do
   matching_pods=(`kubectl -n $namespace get pods --output=jsonpath='{.items[*].metadata.name}' | xargs -n1`)
   for pod in ${matching_pods[@]};
   do
     kubectl -n $namespace describe pod $pod | grep -e "Message:"
   done
done
