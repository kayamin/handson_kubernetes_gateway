# single_cluster_gateway


setup

```
gcloud auth application-default login

cd terraform
terraform init
terraform apply

CLUSTER_NAME=gke-cluster
ZONE=asia-northeast1-a
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE 
```


# [Gateway demo](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways#shared_gateways)

## Gatewayclass, Gateway, HTTPRoute 利用例
```
cd ../k8s

❯ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" \
| kubectl apply -f -
customresourcedefinition.apiextensions.k8s.io/backendpolicies.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tcproutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/tlsroutes.networking.x-k8s.io created
customresourcedefinition.apiextensions.k8s.io/udproutes.networking.x-k8s.io created

❯ kubectl get gatewayclass

NAME          CONTROLLER                  AGE
gke-l7-gxlb   networking.gke.io/gateway   11s
gke-l7-rilb   networking.gke.io/gateway   11s


❯ kubectl apply -f gateway.yaml

gateway.networking.x-k8s.io/internal-http created

❯ kubectl get gateway
NAME            CLASS         AGE
internal-http   gke-l7-rilb   32s

❯ kubectl describe gateway internal-http
Name:         internal-http
Namespace:    default
Labels:       <none>
Annotations:  networking.gke.io/last-reconcile-time: Sunday, 31-Oct-21 03:27:34 UTC
API Version:  networking.x-k8s.io/v1alpha1
Kind:         Gateway
Metadata:
  Creation Timestamp:  2021-10-31T03:27:19Z
  Finalizers:
    gateway.finalizer.networking.gke.io
  Generation:  1
  Managed Fields:
    API Version:  networking.x-k8s.io/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:gatewayClassName:
      f:status:
        .:
        f:conditions:
          .:
          k:{"type":"Scheduled"}:
            .:
            f:lastTransitionTime:
            f:message:
            f:reason:
            f:status:
            f:type:
    Manager:      kubectl-client-side-apply
    Operation:    Update
    Time:         2021-10-31T03:27:19Z
    API Version:  networking.x-k8s.io/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          f:networking.gke.io/last-reconcile-time:
        f:finalizers:
          .:
          v:"gateway.finalizer.networking.gke.io":
      f:spec:
        f:listeners:
      f:status:
        f:addresses:
    Manager:         GoogleGKEGatewayController
    Operation:       Update
    Time:            2021-10-31T03:27:35Z
  Resource Version:  5567
  UID:               c4fd9dbb-bf18-48da-9d21-cbb2c1d34c6b
Spec:
  Gateway Class Name:  gke-l7-rilb
  Listeners:
    Port:      80
    Protocol:  HTTP
    Routes:
      Group:  networking.x-k8s.io
      Kind:   HTTPRoute
      Namespaces:
        From:  Same
      Selector:
        Match Labels:
          Gateway:  internal-http
Status:
  Addresses:
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age   From                   Message
  ----     ------  ----  ----                   -------
  Normal   ADD     56s   sc-gateway-controller  default/internal-http
  Normal   UPDATE  56s   sc-gateway-controller  default/internal-http
  Warning  SYNC    41s   sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5' is not ready

# proxy only subnet が無いので失敗？？
❯ kubectl describe gateway internal-http
Name:         internal-http
Namespace:    default
~
Status:
  Addresses:
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age    From                   Message
  ----     ------  ----   ----                   -------
  Normal   ADD     6m22s  sc-gateway-controller  default/internal-http
  Normal   UPDATE  6m22s  sc-gateway-controller  default/internal-http
  Warning  SYNC    6m7s   sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5' is not ready
  Warning  SYNC    2m34s  sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: Invalid value for field 'resource.target': 'regions/asia-northeast1/targetHttpProxies/gkegw-eimu-default-internal-http-2jzr7e3xclhj'. A reserved and active subnetwork is required in the same region and VPC as the forwarding rule.

# proxy only subnet 作成後 (リトライされ，無事作成された）
Status:
  Addresses:
    Type:   IPAddress
    Value:  10.0.1.4
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age                  From                   Message
  ----     ------  ----                 ----                   -------
  Normal   ADD     25m                  sc-gateway-controller  default/internal-http
  Warning  SYNC    25m                  sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5' is not ready
  Warning  SYNC    4m46s (x6 over 22m)  sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: Invalid value for field 'resource.target': 'regions/asia-northeast1/targetHttpProxies/gkegw-eimu-default-internal-http-2jzr7e3xclhj'. A reserved and active subnetwork is required in the same region and VPC as the forwarding rule.
  Normal   SYNC    70s                  sc-gateway-controller  SYNC on default/internal-http was a success
  Normal   UPDATE  46s (x4 over 25m)    sc-gateway-controller  default/internal-http

# 一旦 delete して再作成したらエラーになった
❯ kubectl describe gateway internal-http | tail -n 20
      Kind:   HTTPRoute
      Namespaces:
        From:  Same
      Selector:
        Match Labels:
          Gateway:  internal-http
Status:
  Addresses:
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age    From                   Message
  ----     ------  ----   ----                   -------
  Normal   ADD     3m3s   sc-gateway-controller  default/internal-http
  Normal   UPDATE  3m2s   sc-gateway-controller  default/internal-http
  Warning  SYNC    2m40s  sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5' is not ready

# 4分ほどしたら作成完了
❯ kubectl describe gateway internal-http | tail -n 20
      Selector:
        Match Labels:
          Gateway:  internal-http
Status:
  Addresses:
    Type:   IPAddress
    Value:  10.0.1.5
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type     Reason  Age                 From                   Message
  ----     ------  ----                ----                   -------
  Normal   ADD     3m57s               sc-gateway-controller  default/internal-http
  Warning  SYNC    3m34s               sc-gateway-controller  generic::invalid_argument: error ensuring load balancer: Insert: The resource 'projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5' is not ready
  Normal   UPDATE  4s (x3 over 3m56s)  sc-gateway-controller  default/internal-http
  Normal   SYNC    4s                  sc-gateway-controller  SYNC on default/internal-http was a success

❯ curl -o deployment_service.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/gke-networking-recipes/master/gateway/gke-gateway-controller/app/store.yaml

❯ k apply -f store-deployment-service.yaml
deployment.apps/store-v1 created
service/store-v1 created
deployment.apps/store-v2 created
service/store-v2 created
deployment.apps/store-german created
service/store-german created

❯ k get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/store-german-66dcb75977-d6jws   1/1     Running   0          29s
pod/store-german-66dcb75977-vdxf7   1/1     Running   0          29s
pod/store-v1-65b47557df-5xhg2       1/1     Running   0          30s
pod/store-v1-65b47557df-9hh5s       1/1     Running   0          30s
pod/store-v2-6856f59f7f-n8qb5       1/1     Running   0          29s
pod/store-v2-6856f59f7f-snchr       1/1     Running   0          29s

NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/kubernetes     ClusterIP   10.0.2.1     <none>        443/TCP    48m
service/store-german   ClusterIP   10.0.2.233   <none>        8080/TCP   30s
service/store-v1       ClusterIP   10.0.2.117   <none>        8080/TCP   31s
service/store-v2       ClusterIP   10.0.2.188   <none>        8080/TCP   30s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/store-german   2/2     2            2           30s
deployment.apps/store-v1       2/2     2            2           31s
deployment.apps/store-v2       2/2     2            2           31s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/store-german-66dcb75977   2         2         2       30s
replicaset.apps/store-v1-65b47557df       2         2         2       31s
replicaset.apps/store-v2-6856f59f7f       2         2         2       31s

❯ kubectl describe svc store-v1
Name:              store-v1
Namespace:         default
Labels:            <none>
Annotations:       cloud.google.com/neg: {"ingress":true}
Selector:          app=store,version=v1
Type:              ClusterIP
IP Families:       <none>
IP:                10.0.2.117
IPs:               10.0.2.117
Port:              <unset>  8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.0.0.12:8080,10.0.0.13:8080
Session Affinity:  None
Events:            <none>

❯ kubectl apply -f store-route.yaml
httproute.networking.x-k8s.io/store created

❯ kubectl get httproute
NAME    HOSTNAMES               AGE
store   ["store.example.com"]   13s

❯ kubectl describe httproute store

Name:         store
Namespace:    default
Labels:       gateway=internal-http
~
Status:
  Gateways:
    Conditions:
      Last Transition Time:  2021-10-31T04:13:44Z
      Message:
      Reason:                RouteAdmitted
      Status:                True
      Type:                  Admitted
      Last Transition Time:  2021-10-31T04:13:44Z
      Message:
      Reason:                ReconciliationSucceeded
      Status:                True
      Type:                  Reconciled
    Gateway Ref:
      Name:       internal-http
      Namespace:  default
Events:
  Type    Reason  Age                  From                   Message
  ----    ------  ----                 ----                   -------
  Normal  ADD     5m41s                sc-gateway-controller  default/store
  Normal  SYNC    27s (x2 over 4m19s)  sc-gateway-controller  Bind of HTTPRoute "default/store" to Gateway "default/internal-http" was a success
  Normal  SYNC    27s (x2 over 4m19s)  sc-gateway-controller  Reconciliation of HTTPRoute "default/store" bound to Gateway "default/internal-http" was a success

# NEGに関する annotationが追加されている
❯ kubectl describe svc store-v1
Name:              store-v1
Namespace:         default
Labels:            <none>
Annotations:       cloud.google.com/neg: {"exposed_ports":{"8080":{}}}
                   cloud.google.com/neg-status:
                     {"network_endpoint_groups":{"8080":"k8s1-56da4537-default-store-v1-8080-57a4be82"},"zones":["asia-northeast1-a"]}
Selector:          app=store,version=v1
Type:              ClusterIP
IP Families:       <none>
IP:                10.0.2.117
IPs:               10.0.2.117
Port:              <unset>  8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.0.0.12:8080,10.0.0.13:8080
Session Affinity:  None
Events:
  Type    Reason  Age                From                   Message
  ----    ------  ----               ----                   -------
  Normal  Create  48s                neg-controller         Created NEG "k8s1-56da4537-default-store-v1-8080-57a4be82" for default/store-v1-k8s1-56da4537-default-store-v1-8080-57a4be82--/8080-8080-GCE_VM_IP_PORT-L7 in "asia-northeast1-a".
  Normal  Attach  44s                neg-controller         Attach 2 network endpoint(s) (NEG "k8s1-56da4537-default-store-v1-8080-57a4be82" in zone "asia-northeast1-a")
  Normal  SYNC    27s (x2 over 56s)  sc-gateway-controller  SYNC on default/store-v1 was a success


❯ kubectl get gateway internal-http -o=jsonpath="{.status.addresses[0].value}"

10.0.1.5

❯ kubectl run curlpod --image curlimages/curl:7.78.0 --command -- sleep 3600
pod/curlpod created

❯ kubectl exec curlpod -it -- /bin/sh

/ $ curl -H "host: store.example.com" 10.0.1.5
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "store-v1",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-v1-65b47557df-5xhg2",
  "pod_name_emoji": "👊🏾",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T04:24:20",
  "zone": "asia-northeast1-a"
}

/ $ curl -H "host: store.example.com" 10.0.1.5/de
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "Gutentag!",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-german-66dcb75977-vdxf7",
  "pod_name_emoji": "👩🏽‍💻",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T04:25:08",
  "zone": "asia-northeast1-a"
}

/ $ curl -H "host: store.example.com" -H "env: canary " 10.0.1.5
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "store-v2",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-v2-6856f59f7f-n8qb5",
  "pod_name_emoji": "👱🏼‍♂",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T04:25:41",
  "zone": "asia-northeast1-a"
}

# 優先順位は path の方が上？
/ $ curl -H "host: store.example.com" -H "env: canary " 10.0.1.5/de
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "Gutentag!",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-german-66dcb75977-vdxf7",
  "pod_name_emoji": "👩🏽‍💻",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T04:25:50",
  "zone": "asia-northeast1-a"
}

# 作成されたLBはCLI, コンソールからも確認可能
❯ gcloud compute forwarding-rules list
NAME                                           REGION           IP_ADDRESS  IP_PROTOCOL  TARGET
gkegw-eimu-default-internal-http-2jzr7e3xclhj  asia-northeast1  10.0.1.5    TCP          asia-northeast1/targetHttpProxies/gkegw-eimu-default-internal-http-2jzr7e3xclhj

# 作成されたNEGはCLI, コンソールからも確認可能
❯ gcloud compute network-endpoint-groups list
NAME                                              LOCATION           ENDPOINT_TYPE   SIZE
k8s1-56da4537-default-site-v1-8080-83d2797b       asia-northeast1-a  GCE_VM_IP_PORT  2
k8s1-56da4537-default-store-german-8080-418b8b7a  asia-northeast1-a  GCE_VM_IP_PORT  2
k8s1-56da4537-default-store-v1-8080-57a4be82      asia-northeast1-a  GCE_VM_IP_PORT  2
k8s1-56da4537-default-store-v2-8080-d193ba49      asia-northeast1-a  GCE_VM_IP_PORT  2

```

## 共有Gateway
- 1つの Gateway に複数のRouteを紐付けるケース

```
❯ curl -o site-deployment-service.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/gke-networking-recipes/master/gateway/gke-gateway-controller/app/site.yaml

❯ kubectl apply -f site-deployment-service.yaml
deployment.apps/site-v1 created
service/site-v1 created

❯ kubectl apply -f site-route.yaml
httproute.networking.x-k8s.io/site created

❯ kubectl get httproute
NAME    HOSTNAMES               AGE
site    ["site.example.com"]    42s
store   ["store.example.com"]   23m

❯ kubectl describe httproute site
Name:         site
Namespace:    default
Labels:       gateway=internal-http
Annotations:  <none>
~
Spec:
  Gateways:
    Allow:  SameNamespace
  Hostnames:
    site.example.com
  Rules:
    Forward To:
      Port:          8080
      Service Name:  site-v1
      Weight:        1
    Matches:
      Path:
        Type:   Prefix
        Value:  /
Events:
  Type    Reason  Age   From                   Message
  ----    ------  ----  ----                   -------
  Normal  ADD     48s   sc-gateway-controller  default/site

# しばらくすると gateway と紐付けられた
❯ kubectl describe httproute site
Name:         site
Namespace:    default
Labels:       gateway=internal-http
Annotations:  <none>
API Version:  networking.x-k8s.io/v1alpha1
~~
Spec:
  Gateways:
    Allow:  SameNamespace
  Hostnames:
    site.example.com
  Rules:
    Forward To:
      Port:          8080
      Service Name:  site-v1
      Weight:        1
    Matches:
      Path:
        Type:   Prefix
        Value:  /
Status:
  Gateways:
    Conditions:
      Last Transition Time:  2021-10-31T04:35:09Z
      Message:
      Reason:                RouteAdmitted
      Status:                True
      Type:                  Admitted
      Last Transition Time:  2021-10-31T04:35:09Z
      Message:
      Reason:                ReconciliationSucceeded
      Status:                True
      Type:                  Reconciled
    Gateway Ref:
      Name:       internal-http
      Namespace:  default
Events:
  Type    Reason  Age    From                   Message
  ----    ------  ----   ----                   -------
  Normal  ADD     4m42s  sc-gateway-controller  default/site
  Normal  SYNC    47s    sc-gateway-controller  Bind of HTTPRoute "default/site" to Gateway "default/internal-http" was a success
  Normal  SYNC    47s    sc-gateway-controller  Reconciliation of HTTPRoute "default/site" bound to Gateway "default/internal-http" was a success


❯ kubectl exec curlpod -it -- /bin/sh

/ $ curl -H "host: site.example.com" -H "env: canary " 10.0.1.5/
{
  "cluster_name": "gke-cluster",
  "host_header": "site.example.com",
  "metadata": "site-v1",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "site-v1-86dc4b4fbc-qdknf",
  "pod_name_emoji": "🧍🏽",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T04:35:28",
  "zone": "asia-northeast1-a"
}
```

## 外部Gateway

- 自己証明書を作成して登録する
```
❯ openssl genrsa -out ./handson_gateway 2048
❯ openssl genrsa -out key.pem 2048

❯ vi openssl_config

[req]
default_bits              = 2048
req_extensions            = extension_requirements
distinguished_name        = dn_requirements
prompt                    = no

[extension_requirements]
basicConstraints          = CA:FALSE
keyUsage                  = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName            = @sans_list

[dn_requirements]
0.organizationName        = example
commonName                = store.example.com

[sans_list]
DNS.1                     = store.example.com

❯ openssl req -new -key handson_gateway -out handson_gateway.csr -config openssl_config
❯ openssl req -new -key key.pem -out cert.pem -config openssl_config

❯ openssl x509 -req -signkey key.pem -in csr.pem -out cert.pem -extfile openssl_config -extensions extension_requirements -days 20
Signature ok
subject=/O=example/CN=store.example.com
Getting Private key

❯ gcloud compute ssl-certificates create store-example-com \
    --certificate=cert.pem \
    --private-key=key.pem \
    --global
Created [https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/global/sslCertificates/store-example-com].
NAME               TYPE          CREATION_TIMESTAMP             EXPIRE_TIME                    MANAGED_STATUS
store-example-com  SELF_MANAGED  2021-10-30T22:10:02.077-07:00  2021-11-19T21:09:30.000-08:00

❯ gcloud compute ssl-certificates list
NAME               TYPE          CREATION_TIMESTAMP             EXPIRE_TIME                    MANAGED_STATUS
store-example-com  SELF_MANAGED  2021-10-30T22:10:02.077-07:00  2021-11-19T21:09:30.000-08:00
```

- 外部Gateway を作成する

```
❯ kubectl apply -f external-gateway.yaml

gateway.networking.x-k8s.io/external-http created

❯ kubectl get gateway
NAME            CLASS         AGE
external-http   gke-l7-gxlb   6s
internal-http   gke-l7-rilb   79m

❯ kubectl describe gateway external-http
Name:         external-http
Namespace:    default
Labels:       <none>
Annotations:  networking.gke.io/addresses: gkegw-eimu-default-external-http-jy9mc97xb5yh
              networking.gke.io/backend-services: gkegw-eimu-kube-system-gw-serve404-80-7cq0brelgzex
              networking.gke.io/firewalls: gkegw-l7--gke-vpc
              networking.gke.io/forwarding-rules: gkegw-eimu-default-external-http-jy9mc97xb5yh
              networking.gke.io/health-checks: gkegw-eimu-kube-system-gw-serve404-80-7cq0brelgzex
              networking.gke.io/last-reconcile-time: Sunday, 31-Oct-21 05:14:20 UTC
              networking.gke.io/ssl-certificates:
              networking.gke.io/target-proxies: gkegw-eimu-default-external-http-jy9mc97xb5yh
              networking.gke.io/url-maps: gkegw-eimu-default-external-http-jy9mc97xb5yh
API Version:  networking.x-k8s.io/v1alpha1
Kind:         Gateway
~
Status:
  Addresses:
    Type:   IPAddress
    Value:  34.117.135.52
  Conditions:
    Last Transition Time:  1970-01-01T00:00:00Z
    Message:               Waiting for controller
    Reason:                NotReconciled
    Status:                False
    Type:                  Scheduled
Events:
  Type    Reason  Age                From                   Message
  ----    ------  ----               ----                   -------
  Normal  ADD     64s                sc-gateway-controller  default/external-http
  Normal  UPDATE  16s (x3 over 64s)  sc-gateway-controller  default/external-http
  Normal  SYNC    16s                sc-gateway-controller  SYNC on default/external-http was a success

❯ kubectl apply -f store-external-route.yaml

httproute.networking.x-k8s.io/store-external created

❯ kubectl get httproute
NAME             HOSTNAMES               AGE
site             ["site.example.com"]    45m
store            ["store.example.com"]   67m
store-external   ["store.example.com"]   10s

❯ kubectl describe httproute store-external
Name:         store-external
Namespace:    default
Labels:       gateway=external-http
Annotations:  <none>
API Version:  networking.x-k8s.io/v1alpha1
Kind:         HTTPRoute
~
Spec:
  Gateways:
    Allow:  SameNamespace
  Hostnames:
    store.example.com
  Rules:
    Forward To:
      Port:          8080
      Service Name:  store-v1
      Weight:        1
    Matches:
      Path:
        Type:   Prefix
        Value:  /
Status:
  Gateways:
    Conditions:
      Last Transition Time:  2021-10-31T05:17:10Z
      Message:
      Reason:                RouteAdmitted
      Status:                True
      Type:                  Admitted
      Last Transition Time:  2021-10-31T05:17:10Z
      Message:
      Reason:                ReconciliationSucceeded
      Status:                True
      Type:                  Reconciled
    Gateway Ref:
      Name:       external-http
      Namespace:  default
Events:
  Type    Reason  Age   From                   Message
  ----    ------  ----  ----                   -------
  Normal  ADD     76s   sc-gateway-controller  default/store-external
  Normal  SYNC    12s   sc-gateway-controller  Bind of HTTPRoute "default/store-external" to Gateway "default/external-http" was a success
  Normal  SYNC    12s   sc-gateway-controller  Reconciliation of HTTPRoute "default/store-external" bound to Gateway "default/external-http" was a success

❯ kubectl get gateway external-http -o=jsonpath="{.status.addresses[0].value}"

34.117.135.52

❯ curl https://store.example.com --resolve store.example.com:443:34.117.135.52 --cacert cert.pem -v
* Added store.example.com:443:34.117.135.52 to DNS cache
* Rebuilt URL to: https://store.example.com/
* Hostname store.example.com was found in DNS cache
*   Trying 34.117.135.52...
* TCP_NODELAY set
* Connected to store.example.com (34.117.135.52) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, Server hello (2):
* SSL certificate problem: unable to get local issuer certificate
* stopped the pause stream!
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl performs SSL certificate verification by default, using a "bundle"
 of Certificate Authority (CA) public keys (CA certs). If the default
 bundle file isn't adequate, you can specify an alternate file
 using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
 the bundle, the certificate verification probably failed due to a
 problem with the certificate (it might be expired, or the name might
 not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
HTTPS-proxy has similar options --proxy-cacert and --proxy-insecure.

❯ curl https://store.example.com --resolve store.example.com:443:34.117.135.52 --cacert cert.pem -v -k
* Added store.example.com:443:34.117.135.52 to DNS cache
* Rebuilt URL to: https://store.example.com/
* Hostname store.example.com was found in DNS cache
*   Trying 34.117.135.52...
* TCP_NODELAY set
* Connected to store.example.com (34.117.135.52) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=example; CN=store.example.com
*  start date: Oct 31 05:09:30 2021 GMT
*  expire date: Nov 20 05:09:30 2021 GMT
*  issuer: O=example; CN=store.example.com
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fc6da00e000)
> GET / HTTP/2
> Host: store.example.com
> User-Agent: curl/7.54.0
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200
< content-type: application/json
< content-length: 388
< access-control-allow-origin: *
< server: Werkzeug/1.0.1 Python/3.8.6
< date: Sun, 31 Oct 2021 05:24:12 GMT
< via: 1.1 google
< alt-svc: clear
<
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "store-v1",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-v1-65b47557df-9hh5s",
  "pod_name_emoji": "📿",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T05:24:12",
  "zone": "asia-northeast1-a"
}
* Connection #0 to host store.example.com left intact

❯ curl https://store.example.com --resolve store.example.com:443:34.117.135.52 -v -k
* Added store.example.com:443:34.117.135.52 to DNS cache
* Rebuilt URL to: https://store.example.com/
* Hostname store.example.com was found in DNS cache
*   Trying 34.117.135.52...
* TCP_NODELAY set
* Connected to store.example.com (34.117.135.52) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=example; CN=store.example.com
*  start date: Oct 31 05:09:30 2021 GMT
*  expire date: Nov 20 05:09:30 2021 GMT
*  issuer: O=example; CN=store.example.com
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fc37480e000)
> GET / HTTP/2
> Host: store.example.com
> User-Agent: curl/7.54.0
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200
< content-type: application/json
< content-length: 388
< access-control-allow-origin: *
< server: Werkzeug/1.0.1 Python/3.8.6
< date: Sun, 31 Oct 2021 05:24:40 GMT
< via: 1.1 google
< alt-svc: clear
<
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "store-v1",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-v1-65b47557df-9hh5s",
  "pod_name_emoji": "📿",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T05:24:40",
  "zone": "asia-northeast1-a"
}
* Connection #0 to host store.example.com left intact


❯ gcloud compute forwarding-rules list
NAME                                           REGION           IP_ADDRESS     IP_PROTOCOL  TARGET
gkegw-eimu-default-external-http-jy9mc97xb5yh                   34.117.135.52  TCP          gkegw-eimu-default-external-http-jy9mc97xb5yh
gkegw-eimu-default-internal-http-2jzr7e3xclhj  asia-northeast1  10.0.1.5       TCP          asia-northeast1/targetHttpProxies/gkegw-eimu-default-internal-http-2jzr7e3xclhj
```

## [BackendConfig を利用するとLBのヘルスチェックの設定等をカスタマイズできる](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#configuring_ingress_features_through_backendconfig_parameters)
- Ingress の場合と同様
- Gateway api ではここまではサポートされていないか

```
apiVersion: v1
kind: Service
metadata:
  name: store-v1
  annotations:
    cloud.google.com/backend-config: '{"default": "store-backendconfig"}'
spec:
  selector:
    app: store
    version: v1
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: store-backendconfig
spec:
  healthCheck:
    checkIntervalSec: 15
    port: 15020
    type: HTTPS
    requestPath: /healthz
  connectionDraining:
    drainingTimeoutSec: 60
```

## ルートのマージ、優先度、検証
- 競合するHTTPRouteでも作成には成功する,その場合は作成された時刻が古い順に適用される
- GCLBのUI, CLI から設定されているルールと優先順位を確認できる

優先順位
1. ホスト名のマージ: 最も長い、または最も具体的なホスト名と一致。
2. パスのマージ: 最も長い、または最も具体的なパスと一致。
3. ヘッダーのマージ: 一致する HTTP ヘッダーの最大数。
4. 競合: 前述の 3 つのルールが優先されない場合、最も古いタイムスタンプの HTTPRoute リソースが使用されます。
  

```
❯ kubectl describe httproute store-conflict
Name:         store-conflict
Namespace:    default
Labels:       gateway=internal-http
Annotations:  <none>
API Version:  networking.x-k8s.io/v1alpha1
Kind:         HTTPRoute
~
Spec:
  Gateways:
    Allow:  SameNamespace
  Hostnames:
    store.example.com
  Rules:
    Forward To:
      Port:          8080
      Service Name:  store-v2
      Weight:        1
    Matches:
      Path:
        Type:   Prefix
        Value:  /de
Status:
  Gateways:
    Conditions:
      Last Transition Time:  2021-10-31T05:37:54Z
      Message:
      Reason:                RouteAdmitted
      Status:                True
      Type:                  Admitted
      Last Transition Time:  2021-10-31T05:37:54Z
      Message:
      Reason:                ReconciliationSucceeded
      Status:                True
      Type:                  Reconciled
    Gateway Ref:
      Name:       internal-http
      Namespace:  default
Events:
  Type    Reason  Age    From                   Message
  ----    ------  ----   ----                   -------
  Normal  ADD     2m36s  sc-gateway-controller  default/store-conflict
  Normal  SYNC    106s   sc-gateway-controller  Bind of HTTPRoute "default/store-conflict" to Gateway "default/internal-http" was a success
  Normal  SYNC    106s   sc-gateway-controller  Reconciliation of HTTPRoute "default/store-conflict" bound to Gateway "default/internal-http" was a success

/ $ curl -H "host: store.example.com" 10.0.1.5/de
{
  "cluster_name": "gke-cluster",
  "host_header": "store.example.com",
  "metadata": "Gutentag!",
  "node_name": "gke-gke-cluster-node-pool-a44541b2-pfpl.asia-northeast1-a.c.leaarninggcp-ash.internal",
  "pod_name": "store-german-66dcb75977-vdxf7",
  "pod_name_emoji": "👩🏽‍💻",
  "project_id": "leaarninggcp-ash",
  "timestamp": "2021-10-31T05:42:24",
  "zone": "asia-northeast1-a"
}

# CLI, GCLBのUI から設定されているルールと優先順位を確認できる

❯ gcloud compute url-maps list
NAME                                           DEFAULT_SERVICE
gkegw-eimu-default-external-http-jy9mc97xb5yh  backendServices/gkegw-eimu-kube-system-gw-serve404-80-7cq0brelgzex
gkegw-eimu-default-internal-http-2jzr7e3xclhj

❯ gcloud compute url-maps describe gkegw-eimu-default-internal-http-2jzr7e3xclhj --region asia-northeast1
creationTimestamp: '2021-10-30T20:57:23.858-07:00'
defaultRouteAction:
  faultInjectionPolicy:
    abort:
      httpStatus: 404
      percentage: 100.0
  weightedBackendServices:
  - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5
    weight: 1
fingerprint: 0By5QSYKiFI=
hostRules:
- hosts:
  - store.example.com
  pathMatcher: hostffxyqcv3l2rgbj3v3jakx7trkfuw01ei
- hosts:
  - site.example.com
  pathMatcher: hostzvtty0y30ko0fchfl96u7aj9p7m31ucg
id: '4825114981082311372'
kind: compute#urlMap
name: gkegw-eimu-default-internal-http-2jzr7e3xclhj
pathMatchers:
- defaultRouteAction:
    faultInjectionPolicy:
      abort:
        httpStatus: 404
        percentage: 100.0
    weightedBackendServices:
    - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5
      weight: 1
  name: hostffxyqcv3l2rgbj3v3jakx7trkfuw01ei
  routeRules:
  - matchRules:
    - prefixMatch: /de
    priority: 1
    routeAction:
      weightedBackendServices:
      - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-store-german-8080-o9g73h4mk3ob
        weight: 1
  - matchRules:
    - prefixMatch: /de
    priority: 2
    routeAction:
      weightedBackendServices:
      - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-store-v2-8080-sau4ah4scq2c
        weight: 1
  - matchRules:
    - headerMatches:
      - exactMatch: canary
        headerName: env
      prefixMatch: /
    priority: 3
    routeAction:
      weightedBackendServices:
      - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-store-v2-8080-sau4ah4scq2c
        weight: 1
  - matchRules:
    - prefixMatch: /
    priority: 4
    routeAction:
      weightedBackendServices:
      - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-store-v1-8080-t7d6vxl1jy1d
        weight: 1
- defaultRouteAction:
    faultInjectionPolicy:
      abort:
        httpStatus: 404
        percentage: 100.0
    weightedBackendServices:
    - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-gw-serve404-80-mcfti8ucx6x5
      weight: 1
  name: hostzvtty0y30ko0fchfl96u7aj9p7m31ucg
  routeRules:
  - matchRules:
    - prefixMatch: /
    priority: 1
    routeAction:
      weightedBackendServices:
      - backendService: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/backendServices/gkegw-eimu-default-site-v1-8080-i63x488am9vi
        weight: 1
region: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1
selfLink: https://www.googleapis.com/compute/v1/projects/leaarninggcp-ash/regions/asia-northeast1/urlMaps/gkegw-eimu-default-internal-http-2jzr7e3xclhj

```
