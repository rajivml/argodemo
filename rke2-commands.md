# RKE2 commands

## Install

```
curl -sL https://get.rke2.io | sh
systemctl daemon-reload
systemctl start rke2-server
```

Various exploration/debug commmands for RKE2

## binaries

```
$ ls -la /var/lib/rancher/rke2/bin/
total 263716
drwxr-xr-x 2 root root      4096 Oct  9 15:53 .
drwxr-xr-x 3 root root      4096 Oct  9 15:53 ..
-rwxr-xr-x 1 root root  35422984 Oct  9 15:53 containerd
-rwxr-xr-x 1 root root   7204400 Oct  9 15:53 containerd-shim
-rwxr-xr-x 1 root root  10247488 Oct  9 15:53 containerd-shim-runc-v1
-rwxr-xr-x 1 root root  10255744 Oct  9 15:53 containerd-shim-runc-v2
-rwxr-xr-x 1 root root  21173056 Oct  9 15:53 crictl
-rwxr-xr-x 1 root root  18724136 Oct  9 15:53 ctr
-rwxr-xr-x 1 root root  44474208 Oct  9 15:52 kubectl
-rwxr-xr-x 1 root root 111544592 Oct  9 15:53 kubelet
-rwxr-xr-x 1 root root  10683624 Oct  9 15:53 runc
-rwxr-xr-x 1 root root    285008 Oct  9 15:53 socat
```

## tar.gz install contents

```
/usr/local/share/
/usr/local/share/rke2/
/usr/local/share/rke2/rke2-cis-sysctl.conf
/usr/local/share/rke2/LICENSE.txt
/usr/local/bin/
/usr/local/bin/rke2
/usr/local/bin/rke2-uninstall.sh
/usr/local/bin/rke2-killall.sh
/usr/local/lib/
/usr/local/lib/systemd/
/usr/local/lib/systemd/system/
/usr/local/lib/systemd/system/rke2-server.service
/usr/local/lib/systemd/system/rke2-agent.service
```

## systemd

* `/usr/local/lib/systemd/system/rke2-server.service`

## kubeconfig

```
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
/var/lib/rancher/rke2/bin/kubectl get nodes
```

```
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
```

## containerd

* socket located at `/run/k3s/containerd/containerd.sock`

### ctr

List containers using ctr

```
/var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io container ls
/var/lib/rancher/rke2/bin/ctr -a /run/k3s/containerd/containerd.sock --namespace k8s.io image ls | grep pause
```

### crictl

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
/var/lib/rancher/rke2/bin/crictl ps
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock images | grep pause
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock rmi docker.io/rancher/pause:3.5
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock pull docker.io/rancher/pause:3.5
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock image ls | grep docker.io/rancher/pause:3.5
```

```
/var/lib/rancher/rke2/bin/crictl --config /var/lib/rancher/rke2/agent/etc/crictl.yaml ps
```

```
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock ps -a
```

## logging

* `journalctl -f -u rke2-server`
* `/var/lib/rancher/rke2/agent/containerd/containerd.log`
* `/var/lib/rancher/rke2/agent/logs/kubelet.log`

## etcd

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
```

* `etcdctl check perf`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 etcdctl check perf"
```

* `etcdctl endpoint status`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 etcdctl endpoint status --cluster --write-out=table"
```

* `etcdctl endpoint health`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 etcdctl endpoint health --cluster --write-out=table"
```

* `etcdctl alarm list`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer sh -c "ETCDCTL_ENDPOINTS='https://127.0.0.1:2379' ETCDCTL_CACERT='/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt' ETCDCTL_CERT='/var/lib/rancher/rke2/server/tls/etcd/server-client.crt' ETCDCTL_KEY='/var/lib/rancher/rke2/server/tls/etcd/server-client.key' ETCDCTL_API=3 etcdctl alarm list"
```

* curl metrics

```
curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key https://127.0.0.1:2379/metrics
```

## Kubernetes commands

```
kubectl get events --all-namespaces
kubectl get crd | grep rook | xargs -l1 --no-run-if-empty -- sh -c 'kubectl delete crd $0'
kubectl patch crd clusters.ceph.rook.io -p '{"metadata":{"finalizers": []}}' --type=merge
kubectl -n aifabric get jobs | grep hit-count | awk -F ' ' '{print $1}' | xargs -l1 -- sh -c 'kubectl -n aifabric delete job $0'
kubectl get namespaces | grep -E '[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}' | grep -v -e "1712ffff-6e82-4d1c-a235-5aba36aa8e14" -e "2b6bb06a-6b64-4c8b-966e-ab348fcca547" | awk -F ' ' '{print $1}' | xargs -l1 -- sh -c 'kubectl delete namespace --namespace="$0"'
kubectl get customresourcedefinitions | grep management.cattle.io | xargs -l1 --no-run-if-empty -- sh -c 'kubectl delete crd $0'
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
find . -type f -print0 | xargs -0 dos2unix
kubectl -n cattle-system get pods| grep helm-operation | awk -F ' ' '{print $1}' | xargs -l1 -- sh -c 'kubectl -n cattle-system delete pod $0'
```

* Patch CRD's

```
for CRD in $(kubectl get crd | grep longhorn | cut -d " " -f 1 | xargs); do kubectl patch crd -n default $CRD --type merge -p '{"metadata":{"finalizers": [null]}}'; done
for CRD in $(kubectl get crd | grep longhorn | cut -d " " -f 1 | xargs); do kubectl delete crd -n default $CRD; done
```

* Fetch Images

```
echo $(kubectl get pods -n mongodb -o jsonpath="{.items[*].spec.containers[*].image}") $(kubectl get pods -n mongodb -o jsonpath="{.items[*].spec.initContainers[*].image}") | tr -s '[[:space:]]' '\n' | sort | uniq
```

* Fetch Images All Namespaces

```
for namespace in $(kubectl get ns | cut -d " " -f 1 | xargs); do echo $(kubectl get pods -n $namespace -o jsonpath="{.items[*].spec.containers[*].image}") $(kubectl get pods -n $namespace -o jsonpath="{.items[*].spec.initContainers[*].image}") | tr -s '[[:space:]]' '\n' | sort | uniq; done
```

* Fetch Priority Classes

```
for deploy in $(kubectl get deploy -oname -n xxx | xargs); do echo $deploy;echo $(kubectl get $deploy -n xxx -o json | jq -r '.spec.template.spec.priorityClassName');  done
```

* Fetch Pods By Label

```
for pod in $(kubectl -n mongodb get pods --selector=app=ops-manager-svc -oname | awk -F "/" '{print $2}' | xargs); do echo $pod;  done
```


* PSPS

```
 kubectl edit K8sPSPPrivilegedContainer psp-privileged-container
 kubectl edit K8sPSPAllowedUsers psp-pods-allowed-user-ranges 
 kubectl edit K8sPSPAllowPrivilegeEscalationContainer psp-allow-privilege-escalation-container 
 kubectl edit K8sPSPVolumeTypes psp-volume-types 
 kubectl edit K8sPSPReadOnlyRootFilesystem psp-readonlyrootfilesystem 
 kubectl edit K8sPSPCapabilities psp-capabilities
 kubectl edit K8sBlockHostNetwork block-host-network
 ```

* Check Connectivity URL
```
if nc -z -v -w5 loki:3100 &>/dev/null; then echo "connected"; else echo "not able to connect"; fi
```

* Total Capacity of Cluster

```
total_cpu=0
total_memory=0

nodes=$(kubectl get node --no-headers -o custom-columns=NAME:.metadata.name)

for node in $nodes; do
  echo "Node: $node"
  cpu=$(kubectl get node $node -o json | jq -r '.status.capacity.cpu')
  memory=$(kubectl get node $node -o json | jq -r '.status.capacity."ephemeral-storage"' | tr -d 'Mi')
  total_cpu=$((total_cpu + cpu))
  total_memory=$((total_memory + memory))
  echo
done

echo "Total CPU: $total_cpu"
echo "Total memory: $total_memory"
```

* Total PVC Size

```
total_capacity=0

namespaces=$(kubectl get pvc -A --no-headers -o custom-columns=NAME:.metadata.namespace | sort | uniq)

for namespace in $namespaces; do
  pvcs=$(kubectl get pvc -n $namespace --no-headers -o custom-columns=NAME:.metadata.name)
  for pvc in $pvcs; do
      storage=$(kubectl -n $namespace get pvc $pvc -ojson | jq -r '.status.capacity.storage' | grep Gi | tr -d 'Gi')
      total_capacity=$((total_capacity + storage))
  done
done

echo "Total Capacity: $total_capacity"
```

* Sort Pods by Timestamp

```
kubectl get pods --all-namespaces --sort-by=.metadata.creationTimestamp
```

* Fetch PodID

```
kubectl get pods -n <namespace> <pod-name> -o jsonpath='{.metadata.uid}'
```

* Failed Scheduling

```
kubectl get events -A | grep FailedScheduling
```

* SCP

```
scp -rp testadmin@51.145.209.211:/home/testadmin/perf/ perf/
```

* Accessing local HTML files

```
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --user-data-dir="C:\Chrome_Data\OO7" --allow-file-access-from-files
```

* Port forwarding from Local

```
kubectl -n rabbitmq port-forward service/rabbitmq 8800:15672
kubectl -n rook-ceph port-forward service/rook-ceph-mgr-dashboard 8800:8443
```

* Un-Install MongoDB

```
kubectl delete all --all -n mongodb

kubectl -n mongodb get pvc --ignore-not-found -o name  | grep -E 'data-mongodb-replica-|data-ops-manager|data-uipath-oplog-db|head-ops-manager-backup-daemon|mongodb-versions-ops-manager' | xargs -l1 --no-run-if-empty -- sh -c 'kubectl -n mongodb delete $0'

```

* Garbage Collection

```
https://github.com/k3s-io/k3s/issues/1900

https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cluster_administration/admin-guide-garbage-collection
https://github.com/containerd/containerd/blob/main/docs/garbage-collection.md
https://github.com/k3s-io/k3s/commit/dfd4e42e57b3ff3080469cb929b8f37ffb04dede
https://v1-21.docs.kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images
https://stackoverflow.com/questions/45592781/how-to-change-kubernetes-garbage-collection-threshold-values
https://jvns.ca/blog/2019/11/18/how-containers-work--overlayfs/ 

export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
/var/lib/rancher/rke2/bin/crictl rmi --prune
```

* CEPH Commands

```
ceph osd lspools
rados lspools
ceph osd dump
ceph osd df
ceph df
ceph df detail
ceph health
ceph health detail
ceph osd dump
ceph -s
radosgw-admin gc process
radosgw-admin bucket stats | grep '"size_kb":'
rados -p rook-ceph-store.rgw.buckets.data ls
radosgw-admin object stat --bucket=hailmary --object=breaknow
rados -p .rgw.buckets stat "default.25941.2__multipart_8MiB.2~7HMRML_6La66Dn7AqEa9WV3wLHCny5Z.1"
ceph osd status
ceph osd pool ls detail
rados df
ceph health detail | ag 'not deep-scrubbed since' | awk '{print $2}' | while read pg; do ceph pg deep-scrub $pg; done

```

* Disable Self Heal 
```
kubectl -n argocd patch application automationhub --type=json -p '[
{"op":"replace","path":"/spec/syncPolicy/automated/selfHeal","value":false}
]'
```

* CEPH
```
https://github.com/rook/rook/blob/master/Documentation/ceph-osd-mgmt.md#remove-an-osd-from-a-pvc
https://github.com/rook/rook/blob/master/Documentation/ceph-cluster-crd.md#storage-class-device-sets
https://raw.githubusercontent.com/rook/rook/master/deploy/examples/osd-purge.yaml
https://docs.ceph.com/en/latest/rados/operations/add-or-rm-osds/#removing-osds-manual
#ceph recovery status https://docs.ceph.com/en/latest/rados/operations/add-or-rm-osds/#observe-the-data-migration
ceph -w 
ceph df
ceph osd df
ceph osd dump | grep full_ratio
ceph osd stat
ceph osd tree
ceph osd tree down
ceph status
ceph osd status
ceph osd utilization
ceph pg dump
ceph pg dump -o {filename} --format=json
https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-osd/#stopping-w-out-rebalancing
ceph pg stat
#no to single node cluster
https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-pg/#one-node-cluster
https://docs.ceph.com/en/latest/rados/troubleshooting/memory-profiling/
https://docs.ceph.com/en/latest/rados/troubleshooting/cpu-profiling/
https://min.io/product/erasure-code-calculator
#CEPH garbage collection
https://stackoverflow.com/questions/46846647/ceph-s3-bucket-space-not-freeing-up
#CEPH common issues
https://github.com/rook/rook/tree/master/Documentation
https://github.com/rook/rook/blob/master/Documentation/ceph-disaster-recovery.md#restoring-mon-quorum
https://rook.io/docs/rook/v1.8/ceph-osd-mgmt.html
https://github.com/rook/rook/blob/master/Documentation/ceph-object-store-crd.md#object-store-settings

kubectl -n argocd patch application rook-ceph-object-store --type=json -p '[
{"op":"replace","path":"/spec/syncPolicy/automated/selfHeal","value":false}
]'
* Delete application
kubectl -n rook-ceph patch CephCluster rook-ceph -p '{"metadata":{"finalizers": []}}' --type=merge
kubectl -n rook-ceph patch CephObjectStore rook-ceph -p '{"metadata":{"finalizers": []}}' --type=merge
rm -rf /var/lib/rook/
or
for CRD in $(kubectl get crd -n rook-ceph | grep rook.io | cut -d " " -f 1 | xargs); do kubectl patch crd -n rook-ceph $CRD --type merge -p '{"metadata":{"finalizers": [null]}}'; done

```

#Fetch Passwords Rancher
```
 kubectl get secrets/rancher-admin-password -n cattle-system -o "jsonpath={.data['password']}" | echo $(base64 -d)
```

#Rook Alerting SOP's
```
https://red-hat-storage.github.io/ocs-sop/sop/index.html
https://uipath-product.slack.com/archives/C02E3B9991N/p1645515800067609?thread_ts=1645169044.462809&cid=C02E3B9991N
```

#Erasure Coding
```
https://www.youtube.com/watch?v=Q5kVuM7zEUI
https://www.youtube.com/watch?v=CryhjBWQHvM
https://min.io/product/erasure-code-calculator
[https://min.io/product/erasure-code-calculator](#11-hello-world)
```
