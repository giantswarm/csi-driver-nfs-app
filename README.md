[![CircleCI](https://dl.circleci.com/status-badge/img/gh/giantswarm/csi-driver-nfs-app/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/giantswarm/csi-driver-nfs-app/tree/main)

# csi-driver-nfs chart

Giant Swarm offers a csi-driver-nfs App which can be installed in kubernetes clusters.
This app packages the helm chart for [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) for use in the Giant Swarm App Platform.

**What is this app?**

This is a repository for NFS CSI driver, csi plugin name: nfs.csi.k8s.io.
It supports dynamic provisioning of Persistent Volumes via Persistent Volume Claims by creating a new sub directory under NFS server.

**Who can use it?**

This driver requires an existing and already configured NFSv3 or NFSv4 server.

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
