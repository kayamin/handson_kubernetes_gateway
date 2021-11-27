# multi_cluster_gateway


setup 

- 同じVPCに３つのサブネットを作成し、それぞれにクラスタを作成する
- 

# [マルチクラスタ ゲートウェイの有効化](https://cloud.google.com/kubernetes-engine/docs/how-to/enabling-multi-cluster-gateways)

```
❯   gcloud services enable \
    container.googleapis.com \
    gkehub.googleapis.com \
    multiclusterservicediscovery.googleapis.com \
    multiclusteringress.googleapis.com \
    trafficdirector.googleapis.com \
    --project=leaarninggcp-ash
Operation "operations/acf.p2-913435536820-8cbb0318-8577-47b3-b199-db9bff535132" finished successfully.

❯ terraform apply

❯ gcloud container clusters list
NAME   LOCATION           MASTER_VERSION    MASTER_IP       MACHINE_TYPE  NODE_VERSION      NUM_NODES  STATUS
alpha  asia-northeast1-a  1.20.10-gke.301   35.194.103.199  e2-medium     1.20.10-gke.301   1          RUNNING
beta   asia-northeast1-b  1.20.10-gke.1600  34.146.153.152  e2-medium     1.20.10-gke.1600  1          RUNNING
gamma  asia-northeast1-c  1.20.10-gke.1600  34.85.118.241   e2-medium     1.20.10-gke.1600  1          RUNNING

❯ gcloud container hub memberships list
NAME   EXTERNAL_ID
alpha  046a4408-ced5-4e18-b644-e16ed0d0ec88
beta   63458721-eefc-4f72-84df-321f7aa3efa2
gamma  f0ff0555-0f57-4132-adb2-d20de71ff7bf

❯ gcloud container hub multi-cluster-services describe
createTime: '2021-11-04T12:29:29.336949563Z'
name: projects/leaarninggcp-ash/locations/global/features/multiclusterservicediscovery
resourceState:
  state: ACTIVE
spec: {}
updateTime: '2021-11-04T12:29:29.619831046Z'

❯ gcloud container clusters get-credentials alpha --zone=asia-northeast1-a --project=leaarninggcp-ash
Fetching cluster endpoint and auth data.
kubeconfig entry generated for alpha.
❯ gcloud container clusters get-credentials beta --zone=asia-northeast1-b --project=leaarninggcp-ash
Fetching cluster endpoint and auth data.
kubeconfig entry generated for beta.
❯ gcloud container clusters get-credentials gamma --zone=asia-northeast1-c --project=leaarninggcp-ash
Fetching cluster endpoint and auth data.
kubeconfig entry generated for gamma.


# MCS にクラスタが登録されないので調査 -> CPUが不足していた gke-mcs-importer の起動ができていなかった
❯ k get po -A
NAMESPACE     NAME                                             READY   STATUS    RESTARTS   AGE
gke-mcs       gke-mcs-importer-7db665f4b7-b8c5n                0/1     Pending   0          13m


❯ k describe po  gke-mcs-importer-7db665f4b7-b8c5n -n gke-mcs
Name:           gke-mcs-importer-7db665f4b7-b8c5n
Namespace:      gke-mcs
~
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  25s (x12 over 13m)  default-scheduler  0/1 nodes are available: 1 Insufficient cpu.
  
❯ kubectl view-allocations -u
 Resource                                                Utilization      Requested         Limit  Allocatable   Free
  attachable-volumes-gce-pd                                       __             __            __         15.0     __
  └─ gke-gamma-gamma-219ae624-4krc                                __             __            __         15.0     __
  cpu                                                     (4%) 41.0m   (92%) 861.0m  (27%) 253.0m       940.0m  79.0m
  └─ gke-gamma-gamma-219ae624-4krc                        (4%) 41.0m   (92%) 861.0m  (27%) 253.0m       940.0m  79.0m
     ├─ event-exporter-gke-67986489c8-6sx6n                     2.0m             __            __           __     __
     ├─ fluentbit-gke-z5s2b                                     3.0m         100.0m            __           __     __
     ├─ gke-metadata-server-h4z88                               1.0m         100.0m        100.0m           __     __
     ├─ gke-metrics-agent-clr9x                                 2.0m           3.0m            __           __     __
     ├─ konnectivity-agent-585bf9bbd4-twwmv                     1.0m             __            __           __     __
     ├─ konnectivity-agent-autoscaler-6cb774c9cc-hkhd7          1.0m          10.0m            __           __     __
     ├─ kube-dns-autoscaler-844c9d9448-dj25p                    1.0m          20.0m            __           __     __
     ├─ kube-dns-b4f5c58c7-7bz76                                4.0m         260.0m            __           __     __
     ├─ kube-proxy-gke-gamma-gamma-219ae624-4krc                1.0m         100.0m            __           __     __
     ├─ l7-default-backend-56cb9644f6-q8xhr                     1.0m          10.0m         10.0m           __     __
     ├─ mcs-core-dns-67fccfd95d-bvzzv                           1.0m         100.0m            __           __     __
     ├─ mcs-core-dns-67fccfd95d-dv5t6                           1.0m         100.0m            __           __     __
     ├─ mcs-core-dns-autoscaler-5c99f6649-sr664                 1.0m            0.0            __           __     __
     ├─ metrics-server-v0.3.6-9c5bbf784-smc7h                  18.0m          48.0m        143.0m           __     __
     ├─ netd-2fldp                                              1.0m             __            __           __     __
     └─ pdcsi-node-9xlbj                                        2.0m          10.0m            __           __     __


# nodeのCPUを増やしたら成功 
❯ k get po -A
NAMESPACE     NAME                                             READY   STATUS              RESTARTS   AGE
gke-mcs       gke-mcs-importer-7db665f4b7-b8c5n                1/1     Running             0          27m

❯ kubectl view-allocations -u
 Resource                                               Utilization      Requested         Limit  Allocatable    Free
  attachable-volumes-gce-pd                                      __             __            __        127.0      __
  └─ gke-gamma-gamma-6046f71b-0spf                               __             __            __        127.0      __
  cpu                                                            __   (50%) 961.0m  (13%) 253.0m          1.9  969.0m
  └─ gke-gamma-gamma-6046f71b-0spf                               __   (50%) 961.0m  (13%) 253.0m          1.9  969.0m
     ├─ fluentbit-gke-tfv7w                                      __         100.0m            __           __      __
     ├─ gke-mcs-importer-7db665f4b7-b8c5n                        __         100.0m            __           __      __
     ├─ gke-metadata-server-qtgl6                                __         100.0m        100.0m           __      __
     ├─ gke-metrics-agent-5kf8t                                  __           3.0m            __           __      __
     ├─ konnectivity-agent-autoscaler-6cb774c9cc-7dnp4           __          10.0m            __           __      __
     ├─ kube-dns-autoscaler-844c9d9448-2n48z                     __          20.0m            __           __      __
     ├─ kube-dns-b4f5c58c7-tf587                                 __         260.0m            __           __      __
     ├─ kube-proxy-gke-gamma-gamma-6046f71b-0spf                 __         100.0m            __           __      __
     ├─ l7-default-backend-56cb9644f6-t98jw                      __          10.0m         10.0m           __      __
     ├─ mcs-core-dns-67fccfd95d-f8nsc                            __         100.0m            __           __      __
     ├─ mcs-core-dns-67fccfd95d-z2cmr                            __         100.0m            __           __      __
     ├─ metrics-server-v0.3.6-9c5bbf784-2w2hk                    __          48.0m        143.0m           __      __
     └─ pdcsi-node-n4zcg                                         __          10.0m            __           __      __


# しばらくしたら登録され始めていることを確認
❯ gcloud container hub multi-cluster-services describe
createTime: '2021-11-04T12:29:29.336949563Z'
membershipStates:
  projects/913435536820/locations/global/memberships/beta:
    state:
      code: OK
      description: Firewall successfully updated
      updateTime: '2021-11-04T12:55:12.037670717Z'
  projects/913435536820/locations/global/memberships/gamma:
    state:
      code: OK
      updateTime: '2021-11-04T13:00:54.432119854Z'
name: projects/leaarninggcp-ash/locations/global/features/multiclusterservicediscovery
resourceState:
  state: ACTIVE
spec: {}
updateTime: '2021-11-04T12:29:29.619831046Z'

❯ k describe po gke-mcs-importer-df74874c5-64w2c -n gke-mcs
Name:         gke-mcs-importer-df74874c5-64w2c
Namespace:    gke-mcs
~
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  13m (x17 over 33m)   default-scheduler  0/1 nodes are available: 1 Insufficient cpu.
  Warning  FailedScheduling  9m29s (x7 over 12m)  default-scheduler  0/1 nodes are available: 1 node(s) were unschedulable.
  Warning  FailedScheduling  8m36s                default-scheduler  no nodes available to schedule pods
  Warning  FailedScheduling  7m49s (x2 over 8m)   default-scheduler  0/1 nodes are available: 1 node(s) had taint {node.kubernetes.io/not-ready: }, that the pod didn't tolerate.
  Normal   Scheduled         7m39s                default-scheduler  Successfully assigned gke-mcs/gke-mcs-importer-df74874c5-64w2c to gke-beta-beta-0fcf5983-f67t
  Normal   Pulling           7m37s                kubelet            Pulling image "gcr.io/gke-release/gke-mcs-importer:v2.0.2-gke.0"
  Normal   Pulled            7m28s                kubelet            Successfully pulled image "gcr.io/gke-release/gke-mcs-importer:v2.0.2-gke.0" in 9.386550738s
  Normal   Created           7m27s                kubelet            Created container gke-mcs-importer
  Normal   Started           7m27s                kubelet            Started container gke-mcs-importer


```
