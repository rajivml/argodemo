app=aifabric 


rm -rf /aifabric/support_bundle/
echo "deleted folder"

bash /scripts/fetch_logs.sh $app aifabric
bash /scripts/fetch_logs.sh $app default
bash /scripts/fetch_logs.sh $app istio-system 
bash /scripts/fetch_logs.sh $app kube-system
bash /scripts/fetch_logs.sh $app rook-ceph


echo "Starting Storage Check"
OBJECT_GATEWAY_INTERNAL_IP="rook-ceph-rgw-rook-ceph-store"
OBJECT_GATEWAY_INTERNAL_HOST=$(kubectl -n rook-ceph get services/$OBJECT_GATEWAY_INTERNAL_IP -o jsonpath="{.spec.clusterIP}")
OBJECT_GATEWAY_INTERNAL_PORT=$(kubectl -n rook-ceph get services/$OBJECT_GATEWAY_INTERNAL_IP -o jsonpath="{.spec.ports[0].port}")

STORAGE_ACCESS_KEY=$(kubectl -n aifabric get secret storage-secrets --export -o json | jq '.data.OBJECT_STORAGE_ACCESSKEY' | sed -e 's/^"//' -e 's/"$//' | base64 -d)
STORAGE_SECRET_KEY=$(kubectl -n aifabric get secret storage-secrets --export -o json | jq '.data.OBJECT_STORAGE_SECRETKEY' | sed -e 's/^"//' -e 's/"$//' | base64 -d)

export AWS_HOST=$OBJECT_GATEWAY_INTERNAL_HOST
export AWS_ENDPOINT=$OBJECT_GATEWAY_INTERNAL_HOST:$OBJECT_GATEWAY_INTERNAL_PORT
export AWS_ACCESS_KEY_ID=$STORAGE_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$STORAGE_SECRET_KEY

cd /aifabric
zip -r support_bundle.zip /aifabric/support_bundle/

ls -ltr /aifabric

account_id=host
tenant_id=$(kubectl get namespaces | grep -E '[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}' | grep training | cut -d ' ' -f1)
replace=""
tenant_id=${tenant_id/training-/$replace}
user_id=$tenant_id


TRAINER_IP=`kubectl -n aifabric get svc ai-trainer-svc -ojsonpath='{.spec.clusterIP}'`

#upload
trainer_put_url="http://$TRAINER_IP:80/ai-trainer/v1/signedURL?contentType=application%2Foctet-stream&blobName=support-dump%2Fsupport-dump.zip&signingMethod=PUT"
upload_response=`curl $trainer_put_url -H 'tenant-id: '"$tenant_id"'' -H 'user-id: '"$user_id"'' -H 'account-id: '"$account_id"'' --insecure`
put_url_signed=`echo $upload_response | jq -r '.data.url'`
curl -v -k -X 'PUT' -H 'content-type: application/octet-stream' -T /aifabric/support_bundle.zip -L $put_url_signed
	
#GET URL
trainer_get_url="http://$TRAINER_IP:80/ai-trainer/v1/signedURL?blobName=support-dump%2Fsupport-dump.zip&signingMethod=GET"
get_response=`curl $trainer_get_url -H 'tenant-id: '"$tenant_id"'' -H 'user-id: '"$user_id"'' -H 'account-id: '"$account_id"'' --insecure`
get_url_signed=`echo $get_response | jq -r '.data.url'`



echo "########################################## Support Dump ######################################"
echo -e "\e[31m  Please click on this link to download support dump: \e[0m"
echo $get_url_signed


	
	
