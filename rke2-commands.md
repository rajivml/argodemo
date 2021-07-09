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
```

### crictl

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
/var/lib/rancher/rke2/bin/crictl ps
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

