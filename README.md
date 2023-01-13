# Mirroring images

1. Upload images to the registry available in your network, if no registry is passed in the command line `localhost` is used, and if port 5000 is closed, then a new registry is started.

Usage:

```bash
cat images-magnum-ussuri.txt | ./mirror-images.sh <REGISTRY_IP>
```

2. Create a cluster template indicating the container_infra_prefix label and setting the insecure_registry property to the right value, for example (replace `<REGISTRY_IP>` with the right value to your environment).

  ```
  openstack coe cluster template create k8s-cluster-template --image fedora-coreos-32 \
      --keypair testkey --external-network ext_net --dns-nameserver 10.245.160.2 \
      --flavor m1.small  --network-driver flannel  --coe kubernetes \
      --tls-disabled \
      --labels container_infra_prefix=<REGISTRY_IP>:5000/
  openstack coe cluster template update k8s-cluster-template replace insecure_registry=<REGISTRY_IP>:5000
  ```