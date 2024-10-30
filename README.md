[![CircleCI](https://dl.circleci.com/status-badge/img/gh/giantswarm/csi-driver-nfs-app/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/giantswarm/csi-driver-nfs-app/tree/main)

# csi-driver-nfs chart

Giant Swarm offers a csi-driver-nfs App which can be installed in kubernetes clusters.
This app packages the helm chart for [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) for use in the Giant Swarm App Platform.

**What is this app?**

This is a repository for NFS CSI driver, csi plugin name: nfs.csi.k8s.io.
It supports dynamic provisioning of Persistent Volumes via Persistent Volume Claims by creating a new sub directory under NFS server.

**Who can use it?**

This driver requires an existing and already configured NFSv3 or NFSv4 server.

## Requirements

The driver needs privileged container permissions to interact directly with the host system for NFS mount and unmount operations.
By default, Giant Swarm clusters have security policies in place that restrict privileged containers and other sensitive settings.
Below is a recommended  `PolicyException` custom resource that can be applied by an admin to allow the CSI NFS driver privileged access.

```yaml
apiVersion: policy.giantswarm.io/v1alpha1
kind: PolicyException
metadata:
  name: csi-nfs-node
  namespace: policy-exceptions
spec:
  policies:
    - disallow-capabilities
    - disallow-capabilities-strict
    - disallow-host-namespaces
    - disallow-host-path
    - disallow-privilege-escalation
    - disallow-privileged-containers
    - require-run-as-nonroot
    - restrict-volume-types
  targets:
    - kind: DaemonSet
      namespaces:
      - $NAMESPACE
      names:
      - csi-nfs-node*
---
apiVersion: policy.giantswarm.io/v1alpha1
kind: PolicyException
metadata:
  name: csi-nfs-controller
  namespace: policy-exceptions
spec:
  policies:
    - disallow-capabilities
    - disallow-capabilities-strict
    - disallow-host-namespaces
    - disallow-host-path
    - disallow-privilege-escalation
    - disallow-privileged-containers
    - require-run-as-nonroot
    - restrict-volume-types
  targets:
    - kind: Deployment
      namespaces:
      - $NAMESPACE
      names:
      - csi-nfs-controller*
```
Each exception addresses a specific capability required by the CSI NFS driver:

- __disallow-capabilities and disallow-capabilities-strict:__
The driver requires additional Linux capabilities to handle NFS mounts, which necessitates capabilities that exceed standard restrictions. This is essential for managing network file system interactions and mount operations effectively.

- __disallow-host-namespaces:__
Host namespaces are used for file system operations and NFS communication across the Kubernetes node, which requires access to the host’s namespace. This setup is critical for mounting NFS volumes on a per-node basis.

- __disallow-host-path:__
The driver must access host paths to mount NFS volumes. Host paths are necessary to enable the driver to access the storage and network configurations on each node, facilitating NFS storage provisioning.

- __disallow-privilege-escalation:__
Certain driver operations require privilege escalation to perform mount operations and interact with system resources. Disallowing privilege escalation would prevent the driver from managing these tasks effectively.

- __disallow-privileged-containers:__
The driver needs privileged container permissions to interact directly with the host system for NFS mount and unmount operations. This privilege level is vital for the driver's function and stability.

- __require-run-as-nonroot:__
The driver requires root privileges for certain operations, especially when managing NFS mounts on nodes. Running the container as a non-root user would limit access to necessary system resources and disrupt functionality.

- __restrict-volume-types:__
The NFS driver relies on volume types that would otherwise be restricted by default policies. By permitting these volume types, the driver can provision and manage NFS volumes as intended.



## Installing

There are several ways to install this app onto a workload cluster.

- [Using GitOps to instantiate the App](https://docs.giantswarm.io/advanced/gitops/apps/)
- [Using our web interface](https://docs.giantswarm.io/platform-overview/web-interface/app-platform/#installing-an-app).
- By creating an [App resource](https://docs.giantswarm.io/use-the-api/management-api/crd/apps.application.giantswarm.io/) in the management cluster as explained in [Getting started with App Platform](https://docs.giantswarm.io/getting-started/app-platform/).

## Configuring

### values.yaml

**This is an example of a values file you could upload using our web interface.**

```yaml
storageClass:
  create: false
  name: nfs-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  parameters:
    server: nfs-server.default.svc.cluster.local
    share: /
    subDir:
    mountPermissions: "0"
#     csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
    csi.storage.k8s.io/provisioner-secret-name: "mount-options"
    csi.storage.k8s.io/provisioner-secret-namespace: "default"
  reclaimPolicy: Delete
  volumeBindingMode: Immediate
  mountOptions:
    - nfsvers=4.1
```
